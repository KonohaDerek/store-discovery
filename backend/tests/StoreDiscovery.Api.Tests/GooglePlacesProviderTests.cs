using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Xunit;

namespace StoreDiscovery.Api.Tests;

public sealed class GooglePlacesProviderTests
{
    [Fact]
    public async Task Text_search_normalizes_google_place_fields()
    {
        var handler = new StubHandler((request, _) =>
        {
            Assert.Equal("https://places.googleapis.com/v1/places:searchText", request.RequestUri!.ToString());
            Assert.Equal("test-key", request.Headers.GetValues("X-Goog-Api-Key").Single());
            Assert.Contains("places.displayName", request.Headers.GetValues("X-Goog-FieldMask").Single());
            return JsonResponse("""
                {
                  "places": [
                    {
                      "id": "places/cafe-1",
                      "displayName": { "text": "Coffee Lab" },
                      "formattedAddress": "1 Taipei Road",
                      "location": { "latitude": 25.04, "longitude": 121.51 },
                      "types": ["cafe", "establishment"],
                      "currentOpeningHours": { "openNow": true },
                      "googleMapsUri": "https://maps.google.com/?cid=1"
                    }
                  ]
                }
                """);
        });
        var provider = CreateProvider(handler);

        var stores = await provider.DiscoverAsync(
            new DiscoveryQuery { Q = "coffee", Area = "Taipei" },
            CancellationToken.None);

        var store = Assert.Single(stores);
        Assert.Equal("places/cafe-1", store.StoreId);
        Assert.Equal("Coffee Lab", store.Name);
        Assert.Contains("food.cafe", store.Categories);
        Assert.Equal("open", store.OpenState);
        Assert.Equal("google", store.Source);
    }

    [Fact]
    public async Task Supported_category_with_coordinates_uses_nearby_search()
    {
        var handler = new StubHandler((request, _) =>
        {
            Assert.Equal("https://places.googleapis.com/v1/places:searchNearby", request.RequestUri!.ToString());
            using var document = JsonDocument.Parse(
                request.Content!.ReadAsStringAsync().GetAwaiter().GetResult());
            Assert.Equal(
                "cafe",
                document.RootElement.GetProperty("includedTypes")[0].GetString());
            Assert.Equal(
                800,
                document.RootElement
                    .GetProperty("locationRestriction")
                    .GetProperty("circle")
                    .GetProperty("radius")
                    .GetInt32());
            return JsonResponse("{ \"places\": [] }");
        });
        var provider = CreateProvider(handler);

        var stores = await provider.DiscoverAsync(
            new DiscoveryQuery
            {
                Category = "food.cafe",
                Lat = 25.04,
                Lng = 121.51,
                RadiusMeters = 800,
            },
            CancellationToken.None);

        Assert.Empty(stores);
    }

    [Fact]
    public async Task Detail_lookup_maps_hours_contact_and_navigation()
    {
        var handler = new StubHandler((request, _) =>
        {
            Assert.Equal(
                "https://places.googleapis.com/v1/places/ChIJcafe1",
                request.RequestUri!.ToString());
            Assert.Contains(
                "id,displayName,formattedAddress,location",
                request.Headers.GetValues("X-Goog-FieldMask").Single());
            Assert.DoesNotContain(
                "places.id",
                request.Headers.GetValues("X-Goog-FieldMask").Single());
            return JsonResponse("""
                {
                      "id": "ChIJcafe1",
                  "displayName": { "text": "Coffee Lab" },
                  "formattedAddress": "1 Taipei Road",
                  "location": { "latitude": 25.04, "longitude": 121.51 },
                  "types": ["cafe"],
                  "regularOpeningHours": {
                    "weekdayDescriptions": ["Monday: 8:00 AM – 6:00 PM"]
                  },
                  "nationalPhoneNumber": "+886 2 1234 5678",
                  "websiteUri": "https://example.test/coffee",
                  "googleMapsUri": "https://maps.google.com/?cid=1"
                }
                """);
        });
        var provider = CreateProvider(handler);

        var detail = await provider.GetDetailAsync("ChIJcafe1", CancellationToken.None);

        Assert.NotNull(detail);
        Assert.Equal("+886 2 1234 5678", detail.Phone);
        Assert.Equal("Monday: 8:00 AM – 6:00 PM", Assert.Single(detail.BusinessHours));
        Assert.Equal("https://maps.google.com/?cid=1", detail.NavigationTarget);
        Assert.Equal("Google Maps", detail.Attribution);
    }

    [Fact]
    public async Task Provider_http_failure_is_wrapped_for_safe_api_mapping()
    {
        var provider = CreateProvider(new StubHandler((_, _) =>
            new HttpResponseMessage(HttpStatusCode.TooManyRequests)));

        var exception = await Assert.ThrowsAsync<StoreProviderException>(() =>
            provider.DiscoverAsync(
                new DiscoveryQuery { Q = "coffee", Area = "Taipei" },
                CancellationToken.None));

        Assert.Equal("google-discover", exception.Operation);
    }

    private static GooglePlacesProvider CreateProvider(HttpMessageHandler handler) =>
        new(
            new HttpClient(handler),
            Options.Create(new GooglePlacesOptions
            {
                ApiKey = "test-key",
                BaseUrl = "https://places.googleapis.com/",
            }));

    private static HttpResponseMessage JsonResponse(string json) =>
        new(HttpStatusCode.OK)
        {
            Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json"),
        };

    private sealed class StubHandler(
        Func<HttpRequestMessage, CancellationToken, HttpResponseMessage> responder)
        : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken) =>
            Task.FromResult(responder(request, cancellationToken));
    }
}
