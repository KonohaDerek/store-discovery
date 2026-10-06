var builder = WebApplication.CreateBuilder(args);

builder.Logging.ClearProviders();
builder.Logging.AddJsonConsole();
builder.Services
    .AddOptions<StoreDiscoveryOptions>()
    .Bind(builder.Configuration.GetSection("StoreDiscovery"))
    .ValidateDataAnnotations()
    .ValidateOnStart();
builder.Services.AddHealthChecks();
builder.Services.AddSingleton<IStoreProvider, SampleStoreProvider>();

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

app.MapHealthChecks("/health/live");
app.MapHealthChecks("/health/ready");
app.MapGet("/api/v1/health", () => Results.Ok(new { status = "ok" }));
app.MapGet(
    "/api/v1/stores/discover",
    async (
        [AsParameters] DiscoveryQuery query,
        IStoreProvider provider,
        HttpContext context,
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

        var items = await provider.DiscoverAsync(query, cancellationToken);
        return Results.Ok(new DiscoveryResponse(items, null));
    });
app.MapGet(
    "/api/v1/stores/{storeId}",
    async (
        string storeId,
        IStoreProvider provider,
        HttpContext context,
        CancellationToken cancellationToken) =>
    {
        var detail = await provider.GetDetailAsync(storeId, cancellationToken);
        return detail is null
            ? Results.NotFound(new ApiErrorResponse(new ApiError(
                "STORE_NOT_FOUND",
                "The requested store was not found.",
                CorrelationId(context))))
            : Results.Ok(detail);
    });

app.Run();

static string CorrelationId(HttpContext context) =>
    context.Response.Headers["X-Correlation-ID"].FirstOrDefault() ?? context.TraceIdentifier;

public partial class Program;
