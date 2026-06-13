namespace Aosa.Api.Endpoints;

public static class HealthEndpoints
{
    private static readonly DateTime StartTime = DateTime.UtcNow;

    public static void MapHealthEndpoints(this WebApplication app)
    {
        app.MapGet("/api/v1/health", () =>
        {
            return Results.Ok(new
            {
                status = "healthy",
                version = "1.0.0",
                uptime_seconds = (int)(DateTime.UtcNow - StartTime).TotalSeconds
            });
        })
        .WithName("GetHealth")
        .WithTags("Health");
    }
}
