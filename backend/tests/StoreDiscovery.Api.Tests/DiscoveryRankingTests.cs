using Xunit;

namespace StoreDiscovery.Api.Tests;

public sealed class DiscoveryRankingTests
{
    private readonly SampleStoreProvider provider = new();

    [Fact]
    public async Task Results_rank_open_unknown_then_closed()
    {
        var results = await provider.DiscoverAsync(
            new DiscoveryQuery { Q = "a", Area = "Taipei" },
            CancellationToken.None);

        Assert.Equal(
            ["sample-cafe-1", "sample-market-1", "sample-pharmacy-1"],
            results.Select(result => result.StoreId));
    }

    [Fact]
    public async Task Coordinates_replace_fixture_distance_and_apply_radius()
    {
        var results = await provider.DiscoverAsync(
            new DiscoveryQuery
            {
                Q = "a",
                Lat = 25.0478,
                Lng = 121.5170,
                RadiusMeters = 1000
            },
            CancellationToken.None);

        Assert.Equal("sample-cafe-1", results[0].StoreId);
        Assert.Equal(0, results[0].DistanceMeters);
        Assert.Equal(2, results.Count);
        Assert.All(results, result => Assert.True(result.DistanceMeters is <= 1000));
    }

    [Fact]
    public async Task Category_filter_is_case_insensitive()
    {
        var results = await provider.DiscoverAsync(
            new DiscoveryQuery { Category = "FOOD.CAFE", Area = "Taipei" },
            CancellationToken.None);

        var result = Assert.Single(results);
        Assert.Equal("sample-cafe-1", result.StoreId);
    }

    [Fact]
    public async Task Open_now_filter_excludes_unknown_and_closed_stores()
    {
        var results = await provider.DiscoverAsync(
            new DiscoveryQuery
            {
                Q = "a",
                Area = "Taipei",
                OpenNow = true
            },
            CancellationToken.None);

        var result = Assert.Single(results);
        Assert.Equal("sample-cafe-1", result.StoreId);
        Assert.Equal("open", result.OpenState);
    }
}
