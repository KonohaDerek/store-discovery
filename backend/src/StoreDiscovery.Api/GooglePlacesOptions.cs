using System.ComponentModel.DataAnnotations;

public sealed class GooglePlacesOptions
{
    [Required]
    public string ApiKey { get; init; } = string.Empty;

    [Url]
    public string BaseUrl { get; init; } = "https://places.googleapis.com/";

    [Range(1, 20)]
    public int MaxResultCount { get; init; } = 10;
}
