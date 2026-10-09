using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace StoreDiscovery.Api.Tests;

public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;

    public HealthEndpointTests(WebApplicationFactory<Program> factory)
    {
        client = factory.CreateClient();
    }

    [Theory]
    [InlineData("/health/live")]
    [InlineData("/health/ready")]
    public async Task Health_endpoints_return_healthy(string path)
    {
        using var response = await client.GetAsync(path);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Versioned_health_endpoint_returns_ok_status()
    {
        using var response = await client.GetAsync("/api/v1/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("{\"status\":\"ok\"}", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Correlation_id_is_preserved_on_the_response()
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/health/live");
        request.Headers.Add("X-Correlation-ID", "test-correlation-id");

        using var response = await client.SendAsync(request);

        Assert.Equal("test-correlation-id", response.Headers.GetValues("X-Correlation-ID").Single());
    }

    [Fact]
    public async Task Discovery_returns_matching_sample_stores()
    {
        using var response = await client.GetAsync("/api/v1/stores/discover?q=cafe&area=Taipei");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Contains("North Gate Coffee", body);
        Assert.DoesNotContain("Green Cross Pharmacy", body);
    }

    [Fact]
    public async Task Discovery_rejects_missing_intent()
    {
        using var response = await client.GetAsync("/api/v1/stores/discover?area=Taipei");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("INVALID_DISCOVERY_QUERY", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Discovery_rejects_non_finite_coordinates()
    {
        using var response = await client.GetAsync(
            "/api/v1/stores/discover?q=cafe&area=Taipei&lat=NaN&lng=NaN");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("outside the valid range", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Discovery_rejects_radius_without_coordinates()
    {
        using var response = await client.GetAsync(
            "/api/v1/stores/discover?q=cafe&area=Taipei&radiusMeters=500");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains(
            "radiusMeters requires lat and lng",
            await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Store_detail_returns_the_requested_store()
    {
        using var response = await client.GetAsync("/api/v1/stores/sample-cafe-1");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Contains("North Gate Coffee", body);
        Assert.Contains("Sample provider data", body);
    }

    [Fact]
    public async Task Store_detail_returns_not_found_for_unknown_store()
    {
        using var response = await client.GetAsync("/api/v1/stores/missing");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Contains("STORE_NOT_FOUND", await response.Content.ReadAsStringAsync());
    }
}
