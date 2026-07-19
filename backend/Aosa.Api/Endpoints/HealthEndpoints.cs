using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class HealthEndpoints
{
    private static readonly DateTime StartTime = DateTime.UtcNow;

    public static void MapHealthEndpoints(this WebApplication app)
    {
        app.MapGet("/api/v1/health", async (AosaDbContext db, ILoggerFactory loggerFactory) =>
        {
            var logger = loggerFactory.CreateLogger("HealthEndpoint");
            logger.LogInformation("Health check requested");

            var dbOk = false;
            try
            {
                dbOk = await db.Database.CanConnectAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Database connection check failed");
            }

            logger.LogInformation("Health check: db={DbStatus}", dbOk ? "ok" : "failed");
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
