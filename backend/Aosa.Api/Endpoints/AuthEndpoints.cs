using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/auth").WithTags("Authentication");

        group.MapPost("/register", async (
            RegisterRequest request,
            AosaDbContext db) =>
        {
            var existing = await db.DeviceRegistrations
                .FirstOrDefaultAsync(d => d.DeviceId == request.DeviceId);

            if (existing is not null)
            {
                return Results.Conflict(new { error = "device_already_registered" });
            }

            var registration = new DeviceRegistration
            {
                Id = Guid.NewGuid(),
                DeviceId = request.DeviceId,
                DeviceName = request.DeviceName,
                PinPublicSalt = request.PinPublicSalt,
                PublicKey = request.PublicKey,
                RegisteredAt = DateTime.UtcNow
            };

            db.DeviceRegistrations.Add(registration);
            await db.SaveChangesAsync();

            var syncMeta = new SyncMetadata
            {
                Id = Guid.NewGuid(),
                DeviceId = request.DeviceId,
                GlobalVersion = 0,
                LastSyncAt = DateTime.UtcNow
            };

            db.SyncMetadatas.Add(syncMeta);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/devices/{registration.Id}", new
            {
                device_token = "placeholder-jwt",
                refresh_token = "placeholder-refresh",
                server_version = 0
            });
        });

        group.MapPost("/refresh", (RefreshRequest request) =>
        {
            return Results.Ok(new
            {
                device_token = "new-placeholder-jwt",
                refresh_token = "new-placeholder-refresh"
            });
        });
    }
}

public record RegisterRequest(
    Guid DeviceId,
    string DeviceName,
    string PinPublicSalt,
    string PublicKey
);

public record RefreshRequest(string RefreshToken);
