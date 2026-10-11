public sealed class DiscoveryQuery
{
    public string? Q { get; set; }
    public string? Category { get; set; }
    public double? Lat { get; set; }
    public double? Lng { get; set; }
    public int? RadiusMeters { get; set; }
    public bool? OpenNow { get; set; }
    public string? Area { get; set; }
    public string? Cursor { get; set; }

    public string? ValidationError()
    {
        if (string.IsNullOrWhiteSpace(Q) && string.IsNullOrWhiteSpace(Category))
        {
            return "q or category is required.";
        }

        if (Lat.HasValue != Lng.HasValue)
        {
            return "lat and lng must be supplied together.";
        }

        if (!Lat.HasValue && string.IsNullOrWhiteSpace(Area))
        {
            return "lat/lng or area is required.";
        }

        if ((Lat.HasValue && !double.IsFinite(Lat.Value)) ||
            (Lng.HasValue && !double.IsFinite(Lng.Value)) ||
            Lat is < -90 or > 90 ||
            Lng is < -180 or > 180)
        {
            return "lat or lng is outside the valid range.";
        }

        if (RadiusMeters is <= 0 or > 50000)
        {
            return "radiusMeters must be between 1 and 50000.";
        }

        if (RadiusMeters.HasValue && (!Lat.HasValue || !Lng.HasValue))
        {
            return "radiusMeters requires lat and lng.";
        }

        return null;
    }
}

public sealed record StoreLocation(double Lat, double Lng);

public sealed record StoreSummary(
    string StoreId,
    string Name,
    IReadOnlyList<string> Categories,
    int? DistanceMeters,
    string OpenState,
    string AddressSummary,
    StoreLocation Location,
    string Source);

public sealed record DiscoveryResponse(
    IReadOnlyList<StoreSummary> Items,
    string? NextCursor);

public sealed record StoreDetail(
    string StoreId,
    string Name,
    IReadOnlyList<string> Categories,
    int? DistanceMeters,
    string OpenState,
    string AddressSummary,
    StoreLocation Location,
    string Source,
    string FullAddress,
    IReadOnlyList<string> BusinessHours,
    string? Phone,
    string? Website,
    string? NavigationTarget,
    string Attribution);

public sealed record ApiError(string Code, string Message, string CorrelationId);

public sealed record ApiErrorResponse(ApiError Error);

public sealed class StoreProviderException : Exception
{
    public StoreProviderException(string operation, Exception? innerException = null)
        : base($"Store provider operation '{operation}' failed.", innerException)
    {
        Operation = operation;
    }

    public string Operation { get; }
}

public interface IStoreProvider
{
    Task<IReadOnlyList<StoreSummary>> DiscoverAsync(
        DiscoveryQuery query,
        CancellationToken cancellationToken);

    Task<StoreDetail?> GetDetailAsync(
        string storeId,
        CancellationToken cancellationToken);
}

public sealed class SampleStoreProvider : IStoreProvider
{
    private static readonly IReadOnlyList<StoreSummary> Stores =
    [
        new(
            "sample-cafe-1",
            "North Gate Coffee",
            ["food.cafe"],
            350,
            "open",
            "100 Zhongxiao West Road, Taipei",
            new(25.0478, 121.5170),
            "sample"),
        new(
            "sample-market-1",
            "Taipei Central Market",
            ["retail.supermarket", "retail.shopping"],
            700,
            "unknown",
            "1 Civic Boulevard, Taipei",
            new(25.0446, 121.5173),
            "sample"),
        new(
            "sample-pharmacy-1",
            "Green Cross Pharmacy",
            ["health.pharmacy"],
            1100,
            "closed",
            "12 Renai Road, Taipei",
            new(25.0384, 121.5320),
            "sample")
    ];

    public Task<IReadOnlyList<StoreSummary>> DiscoverAsync(
        DiscoveryQuery query,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var search = query.Q?.Trim();
        var category = query.Category?.Trim();
        var items = Stores
            .Where(store =>
                (string.IsNullOrWhiteSpace(category) ||
                 store.Categories.Contains(category, StringComparer.OrdinalIgnoreCase)) &&
                (string.IsNullOrWhiteSpace(search) ||
                 store.Name.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                 store.Categories.Any(value =>
                     value.Contains(search, StringComparison.OrdinalIgnoreCase))))
            .Select(store => WithDistance(store, query))
            .Where(store =>
                !query.RadiusMeters.HasValue ||
                store.DistanceMeters is not null &&
                store.DistanceMeters.Value <= query.RadiusMeters.Value)
            .Where(store =>
                !query.OpenNow.GetValueOrDefault() || store.OpenState == "open")
            .OrderBy(store => OpenStateRank(store.OpenState))
            .ThenBy(store => store.DistanceMeters ?? int.MaxValue)
            .ThenBy(store => store.Name, StringComparer.OrdinalIgnoreCase)
            .ThenBy(store => store.StoreId, StringComparer.Ordinal)
            .ToArray();

        return Task.FromResult<IReadOnlyList<StoreSummary>>(items);
    }

    private static StoreSummary WithDistance(StoreSummary store, DiscoveryQuery query)
    {
        if (!query.Lat.HasValue || !query.Lng.HasValue)
        {
            return store;
        }

        return store with
        {
            DistanceMeters = DistanceMeters(
                query.Lat.Value,
                query.Lng.Value,
                store.Location)
        };
    }

    private static int OpenStateRank(string openState) => openState switch
    {
        "open" => 0,
        "unknown" => 1,
        "closed" => 2,
        _ => 3
    };

    private static int DistanceMeters(double latitude, double longitude, StoreLocation target)
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

    public Task<StoreDetail?> GetDetailAsync(
        string storeId,
        CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var store = Stores.SingleOrDefault(value => value.StoreId == storeId);
        if (store is null)
        {
            return Task.FromResult<StoreDetail?>(null);
        }

        return Task.FromResult<StoreDetail?>(new StoreDetail(
            store.StoreId,
            store.Name,
            store.Categories,
            store.DistanceMeters,
            store.OpenState,
            store.AddressSummary,
            store.Location,
            store.Source,
            store.AddressSummary,
            ["09:00–18:00"],
            null,
            null,
            $"https://maps.google.com/?q={store.Location.Lat},{store.Location.Lng}",
            "Sample provider data"));
    }
}
