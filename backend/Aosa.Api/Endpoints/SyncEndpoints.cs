using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class SyncEndpoints
{
    public static void MapSyncEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/sync")
            .WithTags("Sync")
            .RequireAuthorization();

        group.MapGet("/status", async (AosaDbContext db) =>
        {
            var meta = await db.SyncMetadatas.FirstOrDefaultAsync();
            return Results.Ok(new
            {
                server_version = meta?.GlobalVersion ?? 0,
                device_version = meta?.GlobalVersion ?? 0
            });
        });

        group.MapGet("/pull", async (
            [AsParameters] PullRequest request,
            AosaDbContext db) =>
        {
            var records = await db.OtpRecords
                .Where(r => r.Version > request.SinceVersion)
                .OrderBy(r => r.Version)
                .ToListAsync();

            var serverVersion = await db.SyncMetadatas
                .Select(m => m.GlobalVersion)
                .FirstOrDefaultAsync();

            return Results.Ok(new
            {
                items = records.Select(r => new
                {
                    id = r.Id,
                    encrypted_blob = r.EncryptedBlob,
                    version = r.Version,
                    created_at = r.CreatedAt,
                    updated_at = r.UpdatedAt,
                    deleted_at = r.DeletedAt
                }),
                server_version = serverVersion
            });
        });

        group.MapPost("/push", async (
            PushRequest request,
            AosaDbContext db) =>
        {
            var accepted = new List<object>();
            var conflicts = new List<object>();

            foreach (var change in request.Changes)
            {
                var record = await db.OtpRecords.FindAsync(change.Id);

                if (record is null)
                {
                    record = new Domain.Entities.OtpRecord
                    {
                        Id = change.Id,
                        EncryptedBlob = change.EncryptedBlob,
                        Version = 1,
                        CreatedAt = change.ClientTimestamp,
                        UpdatedAt = change.ClientTimestamp
                    };
                    db.OtpRecords.Add(record);
                    accepted.Add(new { id = change.Id, new_version = 1 });
                }
                else if (change.ExpectedVersion == record.Version)
                {
                    record.EncryptedBlob = change.EncryptedBlob;
                    record.Version++;
                    record.UpdatedAt = change.ClientTimestamp;
                    accepted.Add(new { id = change.Id, new_version = record.Version });
                }
                else
                {
                    conflicts.Add(new
                    {
                        id = change.Id,
                        server_version = record.Version,
                        message = "stale version"
                    });
                }
            }

            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                accepted,
                conflicts
            });
        });
    }
}

public record PullRequest(long SinceVersion);

public record PushRequest(List<PushChange> Changes);

public record PushChange(
    Guid Id,
    string EncryptedBlob,
    int ExpectedVersion,
    DateTime ClientTimestamp
);
