using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace StoreDiscovery.Api.Tests;

public sealed class RateLimitTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;

    public RateLimitTests(WebApplicationFactory<Program> factory)
    {
        client = factory.CreateClient();
    }

    [Fact]
    public async Task Public_store_endpoints_reject_requests_after_the_limit()
    {
        HttpResponseMessage? lastResponse = null;
        for (var attempt = 0; attempt < 61; attempt++)
        {
            lastResponse = await client.GetAsync(
                "/api/v1/stores/discover?q=cafe&area=Taipei");
        }

        Assert.NotNull(lastResponse);
        Assert.Equal(HttpStatusCode.TooManyRequests, lastResponse.StatusCode);
        Assert.Equal(
            "60",
            lastResponse.Headers.RetryAfter?.Delta?.TotalSeconds.ToString("0"));
    }
}
