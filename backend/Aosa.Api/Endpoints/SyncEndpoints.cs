using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class SyncEndpoints
{
    public static void MapSyncEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/sync")
            .WithTags("Sync")
            .RequireAuthorization()
            .RequireRateLimiting("Api");

        group.MapGet("/status", async (
            [AsParameters] SyncStatusQuery query,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var meta = await db.SyncMetadatas
                .FirstOrDefaultAsync(m => m.DeviceId == query.RepoId);

            return Results.Ok(new
            {
                server_version = meta?.GlobalVersion ?? 0,
            });
        });

        group.MapGet("/pull", async (
            [AsParameters] PullRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var records = await db.OtpRecords
                .Where(r => r.RepoId == request.RepoId && r.Version > request.SinceVersion)
                .OrderBy(r => r.Version)
                .ToListAsync();

            var meta = await db.SyncMetadatas
                .FirstOrDefaultAsync(m => m.DeviceId == request.RepoId);

            return Results.Ok(new
            {
                items = records.Select(r => new
                {
                    id = r.Id,
                    encrypted_blob = r.EncryptedBlob,
                    version = r.Version,
                    repo_id = r.RepoId,
                    created_at = r.CreatedAt,
                    updated_at = r.UpdatedAt,
                    deleted_at = r.DeletedAt
                }),
                server_version = meta?.GlobalVersion ?? 0
            });
        });

        group.MapPost("/push", async (
            PushRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var accepted = new List<object>();
            var conflicts = new List<object>();

            foreach (var change in request.Changes)
            {
                var record = await db.OtpRecords.FindAsync(change.Id);

                if (record is null)
                {
                    record = new OtpRecord
                    {
                        Id = change.Id,
                        EncryptedBlob = change.EncryptedBlob,
                        Version = 1,
                        RepoId = change.RepoId,
                        DeviceId = Guid.Empty,
                        CreatedAt = change.ClientTimestamp,
                        UpdatedAt = change.ClientTimestamp,
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

public record SyncStatusQuery(Guid RepoId);
public record PullRequest(Guid RepoId, long SinceVersion);
public record PushRequest(List<PushChange> Changes);
public record PushChange(Guid Id, Guid RepoId, string EncryptedBlob, int ExpectedVersion, DateTime ClientTimestamp);
