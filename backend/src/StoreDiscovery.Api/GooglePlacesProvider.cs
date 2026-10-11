using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Options;

public sealed class GooglePlacesProvider : IStoreProvider
{
    private const string SearchFieldMask =
        "places.id,places.displayName,places.formattedAddress,places.location," +
        "places.types,places.currentOpeningHours.openNow," +
        "places.regularOpeningHours.weekdayDescriptions,places.businessStatus," +
        "places.nationalPhoneNumber,places.websiteUri,places.googleMapsUri";
    private const string DetailFieldMask =
        "id,displayName,formattedAddress,location,types,currentOpeningHours.openNow," +
        "regularOpeningHours.weekdayDescriptions,businessStatus,nationalPhoneNumber," +
        "websiteUri,googleMapsUri";

    private readonly HttpClient client;
    private readonly GooglePlacesOptions options;

    public GooglePlacesProvider(HttpClient client, IOptions<GooglePlacesOptions> options)
    {
        this.client = client;
        this.options = options.Value;
        this.client.BaseAddress = new Uri(this.options.BaseUrl);
    }

    public async Task<IReadOnlyList<StoreSummary>> DiscoverAsync(
        DiscoveryQuery query,
        CancellationToken cancellationToken)
    {
        var nearbyType = TryGetNearbyType(query);
        var (path, requestBody) = nearbyType is not null
            ? ("v1/places:searchNearby", BuildNearbyRequest(query, nearbyType))
            : ("v1/places:searchText", BuildTextRequest(query));

        var response = await SendAsync<GooglePlacesSearchResponse>(
            HttpMethod.Post,
            path,
            requestBody,
            "google-discover",
            SearchFieldMask,
            cancellationToken);
        if (response is null)
        {
            throw new StoreProviderException(
                "google-discover",
                new JsonException("Google Places returned an empty response."));
        }

        return response.Places
            .Select(place => ToSummary(place, query))
            .Where(summary => summary is not null)
            .Select(summary => summary!)
            .ToArray();
    }

    public async Task<StoreDetail?> GetDetailAsync(
        string storeId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(storeId))
        {
            return null;
        }

        var response = await SendAsync<GooglePlace>(
            HttpMethod.Get,
            $"v1/places/{Uri.EscapeDataString(storeId)}",
            null,
            "google-detail",
            DetailFieldMask,
            cancellationToken,
            notFoundIsNull: true);

        if (response is null)
        {
            return null;
        }

        if (response.Location is null)
        {
            throw new StoreProviderException(
                "google-detail",
                new JsonException("Google Places detail did not include a location."));
        }

        return ToDetail(response);
    }

    private async Task<T?> SendAsync<T>(
        HttpMethod method,
        string path,
        object? body,
        string operation,
        string fieldMask,
        CancellationToken cancellationToken,
        bool notFoundIsNull = false)
    {
        EnsureConfigured(operation);

        using var request = new HttpRequestMessage(method, path);
        request.Headers.Add("X-Goog-Api-Key", options.ApiKey);
        request.Headers.Add("X-Goog-FieldMask", fieldMask);
        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }

        try
        {
            using var response = await client.SendAsync(
                request,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken);

            if (notFoundIsNull && response.StatusCode == HttpStatusCode.NotFound)
            {
                return default;
            }

            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(
                    $"Google Places returned HTTP {(int)response.StatusCode}.");
            }

            return await response.Content.ReadFromJsonAsync<T>(cancellationToken);
        }
        catch (StoreProviderException)
        {
            throw;
        }
        catch (OperationCanceledException exception)
            when (!cancellationToken.IsCancellationRequested)
        {
            throw new StoreProviderException(operation, exception);
        }
        catch (HttpRequestException exception)
        {
            throw new StoreProviderException(operation, exception);
        }
        catch (JsonException exception)
        {
            throw new StoreProviderException(operation, exception);
        }
    }

    private void EnsureConfigured(string operation)
    {
        if (string.IsNullOrWhiteSpace(options.ApiKey))
        {
            throw new StoreProviderException(
                operation,
                new InvalidOperationException("Google Places API key is not configured."));
        }
    }

    private object BuildTextRequest(DiscoveryQuery query)
    {
        var text = string.IsNullOrWhiteSpace(query.Q)
            ? query.Category!.Trim()
            : query.Q.Trim();
        if (!query.Lat.HasValue && !string.IsNullOrWhiteSpace(query.Area))
        {
            text = $"{text} in {query.Area.Trim()}";
        }

        var request = new Dictionary<string, object?>
        {
            ["textQuery"] = text,
            ["pageSize"] = options.MaxResultCount,
        };
        if (query.OpenNow == true)
        {
            request["openNow"] = true;
        }

        if (query.Lat.HasValue && query.Lng.HasValue)
        {
            request["locationBias"] = Circle(query, query.RadiusMeters ?? 5000);
        }

        return request;
    }

    private object BuildNearbyRequest(DiscoveryQuery query, string includedType)
    {
        var request = new Dictionary<string, object?>
        {
            ["includedTypes"] = new[] { includedType },
            ["maxResultCount"] = options.MaxResultCount,
            ["locationRestriction"] = Circle(query, query.RadiusMeters ?? 5000),
        };
        if (query.OpenNow == true)
        {
            request["openNow"] = true;
        }

        return request;
    }

    private static object Circle(DiscoveryQuery query, int radiusMeters) => new
    {
        circle = new
        {
            center = new
            {
                latitude = query.Lat!.Value,
                longitude = query.Lng!.Value,
            },
            radius = Math.Clamp(radiusMeters, 1, 50_000),
        },
    };

    private static string? TryGetNearbyType(DiscoveryQuery query)
    {
        if (!string.IsNullOrWhiteSpace(query.Q) ||
            !query.Lat.HasValue ||
            !query.Lng.HasValue ||
            string.IsNullOrWhiteSpace(query.Category))
        {
            return null;
        }

        return query.Category.Trim().ToLowerInvariant() switch
        {
            "cafe" or "food.cafe" => "cafe",
            "restaurant" or "food.restaurant" => "restaurant",
            "bar" or "food.bar" => "bar",
            "bakery" or "food.bakery" => "bakery",
            "pharmacy" or "health.pharmacy" => "pharmacy",
            "supermarket" or "retail.supermarket" => "supermarket",
            _ => null,
        };
    }

    private static StoreSummary? ToSummary(GooglePlace place, DiscoveryQuery query)
    {
        if (string.IsNullOrWhiteSpace(place.Id) || place.Location is null)
        {
            return null;
        }

        var location = ToLocation(place.Location);
        return new StoreSummary(
            place.Id,
            place.DisplayName?.Text ?? "Unnamed place",
            NormalizeCategories(place.Types),
            query.Lat.HasValue && query.Lng.HasValue
                ? DistanceMeters(query.Lat.Value, query.Lng.Value, location)
                : null,
            OpenState(place),
            place.FormattedAddress ?? "Address unavailable",
            location,
            "google");
    }

    private static StoreDetail ToDetail(GooglePlace place)
    {
        var location = ToLocation(place.Location!);
        return new StoreDetail(
            place.Id ?? string.Empty,
            place.DisplayName?.Text ?? "Unnamed place",
            NormalizeCategories(place.Types),
            null,
            OpenState(place),
            place.FormattedAddress ?? "Address unavailable",
            location,
            "google",
            place.FormattedAddress ?? "Address unavailable",
            place.RegularOpeningHours?.WeekdayDescriptions ?? [],
            place.NationalPhoneNumber,
            place.WebsiteUri,
            place.GoogleMapsUri,
            "Google Maps");
    }

    private static IReadOnlyList<string> NormalizeCategories(IReadOnlyList<string>? types)
    {
        if (types is null || types.Count == 0)
        {
            return ["other"];
        }

        return types
            .Select(type => type switch
            {
                "cafe" => "food.cafe",
                "restaurant" => "food.restaurant",
                "bar" => "food.bar",
                "bakery" => "food.bakery",
                "pharmacy" => "health.pharmacy",
                "supermarket" => "retail.supermarket",
                _ => type,
            })
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static string OpenState(GooglePlace place) =>
        place.CurrentOpeningHours?.OpenNow switch
        {
            true => "open",
            false => "closed",
            _ when place.BusinessStatus == "CLOSED_PERMANENTLY" => "closed",
            _ => "unknown",
        };

    private static StoreLocation ToLocation(GoogleLocation location) =>
        new(location.Latitude, location.Longitude);

    private static int DistanceMeters(
        double latitude,
        double longitude,
        StoreLocation target)
    {
        const double earthRadiusMeters = 6_371_000;
        var latitudeDelta = ToRadians(target.Lat - latitude);
        var longitudeDelta = ToRadians(target.Lng - longitude);
        var originLatitude = ToRadians(latitude);
        var targetLatitude = ToRadians(target.Lat);
        var a = Math.Pow(Math.Sin(latitudeDelta / 2), 2) +
            Math.Cos(originLatitude) *
            Math.Cos(targetLatitude) *
            Math.Pow(Math.Sin(longitudeDelta / 2), 2);
        var centralAngle = 2 * Math.Atan2(
            Math.Sqrt(Math.Clamp(a, 0, 1)),
            Math.Sqrt(1 - Math.Clamp(a, 0, 1)));

        return (int)Math.Round(earthRadiusMeters * centralAngle, MidpointRounding.AwayFromZero);
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180;

    private sealed class GooglePlacesSearchResponse
    {
        [JsonPropertyName("places")]
        public List<GooglePlace> Places { get; init; } = [];
    }

    private sealed class GooglePlace
    {
        [JsonPropertyName("id")]
        public string? Id { get; init; }

        [JsonPropertyName("displayName")]
        public GoogleDisplayName? DisplayName { get; init; }

        [JsonPropertyName("formattedAddress")]
        public string? FormattedAddress { get; init; }

        [JsonPropertyName("location")]
        public GoogleLocation? Location { get; init; }

        [JsonPropertyName("types")]
        public List<string>? Types { get; init; }

        [JsonPropertyName("currentOpeningHours")]
        public GoogleOpeningHours? CurrentOpeningHours { get; init; }

        [JsonPropertyName("regularOpeningHours")]
        public GoogleOpeningHours? RegularOpeningHours { get; init; }

        [JsonPropertyName("businessStatus")]
        public string? BusinessStatus { get; init; }

        [JsonPropertyName("nationalPhoneNumber")]
        public string? NationalPhoneNumber { get; init; }

        [JsonPropertyName("websiteUri")]
        public string? WebsiteUri { get; init; }

        [JsonPropertyName("googleMapsUri")]
        public string? GoogleMapsUri { get; init; }
    }

    private sealed class GoogleDisplayName
    {
        [JsonPropertyName("text")]
        public string? Text { get; init; }
    }

    private sealed class GoogleLocation
    {
        [JsonPropertyName("latitude")]
        public double Latitude { get; init; }

        [JsonPropertyName("longitude")]
        public double Longitude { get; init; }
    }

    private sealed class GoogleOpeningHours
    {
        [JsonPropertyName("openNow")]
        public bool? OpenNow { get; init; }

        [JsonPropertyName("weekdayDescriptions")]
        public List<string> WeekdayDescriptions { get; init; } = [];
    }
}
