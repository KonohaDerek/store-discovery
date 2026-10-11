using System.Threading.RateLimiting;
using Microsoft.Extensions.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();
builder.Services
    .AddOptions<StoreDiscoveryOptions>()
    .Bind(builder.Configuration.GetSection("StoreDiscovery"))
    .ValidateDataAnnotations()
    .ValidateOnStart();
var selectedProvider = builder.Configuration["StoreDiscovery:Provider"] ?? "sample";
var googlePlacesOptions = builder.Services
    .AddOptions<GooglePlacesOptions>()
    .Bind(builder.Configuration.GetSection("GooglePlaces"));
if (string.Equals(selectedProvider, "google", StringComparison.OrdinalIgnoreCase))
{
    googlePlacesOptions.ValidateDataAnnotations().ValidateOnStart();
}
builder.Services.AddHealthChecks();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = (context, _) =>
    {
        context.HttpContext.Response.Headers.RetryAfter = "60";
        return ValueTask.CompletedTask;
    };
    options.AddPolicy("public-api", context =>
        RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 60,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }));
});
builder.Services.AddHttpClient<GooglePlacesProvider>();
builder.Services.AddSingleton<SampleStoreProvider>();
builder.Services.AddSingleton<IStoreProvider>(serviceProvider =>
{
    var options = serviceProvider
        .GetRequiredService<IOptions<StoreDiscoveryOptions>>()
        .Value;
    return string.Equals(options.Provider, "google", StringComparison.OrdinalIgnoreCase)
        ? serviceProvider.GetRequiredService<GooglePlacesProvider>()
        : serviceProvider.GetRequiredService<SampleStoreProvider>();
});

var app = builder.Build();

app.Use(async (context, next) =>
{
    var correlationId = context.Request.Headers["X-Correlation-ID"].FirstOrDefault();
    if (string.IsNullOrWhiteSpace(correlationId))
    {
        correlationId = context.TraceIdentifier;
    }

    context.Response.Headers["X-Correlation-ID"] = correlationId;
    using (app.Logger.BeginScope(new Dictionary<string, object> { ["correlationId"] = correlationId }))
    {
        await next();
    }
});
app.UseRateLimiter();

app.MapHealthChecks("/health/live");
app.MapHealthChecks("/health/ready");
app.MapGet("/api/v1/health", () => Results.Ok(new { status = "ok" }));
app.MapGet(
    "/api/v1/stores/discover",
    async (
        [AsParameters] DiscoveryQuery query,
        IStoreProvider provider,
        HttpContext context,
        ILogger<Program> logger,
        CancellationToken cancellationToken) =>
    {
        var validationError = query.ValidationError();
        if (validationError is not null)
        {
            return Results.BadRequest(new ApiErrorResponse(new ApiError(
                "INVALID_DISCOVERY_QUERY",
                validationError,
                CorrelationId(context))));
        }

        try
        {
            var items = await provider.DiscoverAsync(query, cancellationToken);
            return Results.Ok(new DiscoveryResponse(items, null));
        }
        catch (StoreProviderException exception)
        {
            return ProviderUnavailable(context, logger, exception);
        }
    })
    .RequireRateLimiting("public-api");
app.MapGet(
    "/api/v1/stores/{storeId}",
    async (
        string storeId,
        IStoreProvider provider,
        HttpContext context,
        ILogger<Program> logger,
        CancellationToken cancellationToken) =>
    {
        try
        {
            var detail = await provider.GetDetailAsync(storeId, cancellationToken);
            return detail is null
                ? Results.NotFound(new ApiErrorResponse(new ApiError(
                    "STORE_NOT_FOUND",
                    "The requested store was not found.",
                    CorrelationId(context))))
                : Results.Ok(detail);
        }
        catch (StoreProviderException exception)
        {
            return ProviderUnavailable(context, logger, exception);
        }
    })
    .RequireRateLimiting("public-api");

app.Run();

static string CorrelationId(HttpContext context) =>
    context.Response.Headers["X-Correlation-ID"].FirstOrDefault() ?? context.TraceIdentifier;

static IResult ProviderUnavailable(
    HttpContext context,
    ILogger<Program> logger,
    StoreProviderException exception)
{
    logger.LogWarning(
        exception,
        "Store provider request failed for operation {Operation}",
        exception.Operation);

    return Results.Json(
        new ApiErrorResponse(new ApiError(
            "DISCOVERY_PROVIDER_UNAVAILABLE",
            "The store discovery provider is temporarily unavailable.",
            CorrelationId(context))),
        statusCode: StatusCodes.Status503ServiceUnavailable);
}

public partial class Program;
