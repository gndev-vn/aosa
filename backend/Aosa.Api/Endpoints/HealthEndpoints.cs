using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class HealthEndpoints
{
    private static readonly DateTime StartTime = DateTime.UtcNow;

    public static void MapHealthEndpoints(this WebApplication app)
    {
        app.MapGet("/api/v1/health", async (AosaDbContext db) =>
        {
            var dbOk = false;
            try
            {
                dbOk = await db.Database.CanConnectAsync();
            }
            catch
            {
                // ignore
            }

            return Results.Ok(new
            {
                status = dbOk ? "healthy" : "degraded",
                version = "1.0.0",
                uptime_seconds = (int)(DateTime.UtcNow - StartTime).TotalSeconds,
                database = dbOk ? "connected" : "unreachable"
            });
        })
        .WithName("GetHealth")
        .WithTags("Health");
    }
}
