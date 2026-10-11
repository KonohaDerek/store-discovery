using System.Net;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Xunit;

namespace StoreDiscovery.Api.Tests;

public sealed class ProviderErrorTests
{
    [Fact]
    public async Task Discovery_provider_failure_returns_safe_normalized_error()
    {
        using var factory = new ProviderErrorFactory();
        using var client = factory.CreateClient();
        using var request = new HttpRequestMessage(
            HttpMethod.Get,
            "/api/v1/stores/discover?q=cafe&area=Taipei");
        request.Headers.Add("X-Correlation-ID", "provider-test");

        using var response = await client.SendAsync(request);
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.Equal("provider-test", response.Headers.GetValues("X-Correlation-ID").Single());
        Assert.Contains("DISCOVERY_PROVIDER_UNAVAILABLE", body);
        Assert.Contains("provider-test", body);
        Assert.DoesNotContain("provider secret", body);
    }

    [Fact]
    public async Task Store_detail_provider_failure_uses_the_same_error_contract()
    {
        using var factory = new ProviderErrorFactory();
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/api/v1/stores/store-1");
        var body = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        Assert.Contains("DISCOVERY_PROVIDER_UNAVAILABLE", body);
        Assert.DoesNotContain("provider secret", body);
    }

    private sealed class ProviderErrorFactory : WebApplicationFactory<Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.ConfigureServices(services =>
            {
                services.RemoveAll<IStoreProvider>();
                services.AddSingleton<IStoreProvider, ThrowingStoreProvider>();
            });
        }
    }

    private sealed class ThrowingStoreProvider : IStoreProvider
    {
        public Task<IReadOnlyList<StoreSummary>> DiscoverAsync(
            DiscoveryQuery query,
            CancellationToken cancellationToken) =>
            Task.FromException<IReadOnlyList<StoreSummary>>(
                new StoreProviderException(
                    "discover",
                    new InvalidOperationException("provider secret should stay server-side")));

        public Task<StoreDetail?> GetDetailAsync(
            string storeId,
            CancellationToken cancellationToken) =>
            Task.FromException<StoreDetail?>(
                new StoreProviderException(
                    "detail",
                    new InvalidOperationException("provider secret should stay server-side")));
    }
}
