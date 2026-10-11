using System.ComponentModel.DataAnnotations;

public sealed class StoreDiscoveryOptions
{
    [Required]
    public string ServiceName { get; init; } = "store-discovery-api";

    public string Provider { get; init; } = "sample";
}
