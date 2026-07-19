using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using static Aosa.Api.Endpoints.OtpEndpoints;

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
            var repoAccess = await HasRepoAccess(db, query.RepoId, user);
            if (!repoAccess) return Results.Forbid();

            var repoVersion = await db.RepoVersions
                .FirstOrDefaultAsync(rv => rv.RepoId == query.RepoId);

            return Results.Ok(new
            {
                server_version = repoVersion?.GlobalVersion ?? 0,
            });
        });

        group.MapGet("/pull", async (
            [AsParameters] PullRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var repoAccess = await HasRepoAccess(db, request.RepoId, user);
            if (!repoAccess) return Results.Forbid();

            var records = await db.OtpRecords
                .Where(r => r.RepoId == request.RepoId && r.Version > request.SinceVersion)
                .OrderBy(r => r.Version)
                .ToListAsync();

            var repoVersion = await db.RepoVersions
                .FirstOrDefaultAsync(rv => rv.RepoId == request.RepoId);

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
                server_version = repoVersion?.GlobalVersion ?? 0
            });
        });

        group.MapPost("/push", async (
            PushRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var accepted = new List<object>();
            var conflicts = new List<object>();
            var reposToVersion = new HashSet<Guid>();

            foreach (var change in request.Changes)
            {
                var repoAccess = await HasRepoAccess(db, change.RepoId, user);
                if (!repoAccess) continue;

                var record = await db.OtpRecords.FindAsync(change.Id);

                if (record is null)
                {
                    record = new OtpRecord
                    {
                        Id = change.Id,
                        EncryptedBlob = change.EncryptedBlob,
                        Version = 1,
                        RepoId = change.RepoId,
                        CreatedAt = change.ClientTimestamp,
                        UpdatedAt = change.ClientTimestamp,
                    };
                    db.OtpRecords.Add(record);
                    accepted.Add(new { id = change.Id, new_version = 1 });
                    reposToVersion.Add(change.RepoId);
                }
                else if (change.ExpectedVersion == record.Version)
                {
                    record.EncryptedBlob = change.EncryptedBlob;
                    record.Version++;
                    record.UpdatedAt = change.ClientTimestamp;
                    accepted.Add(new { id = change.Id, new_version = record.Version });
                    reposToVersion.Add(change.RepoId);
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

            foreach (var repoId in reposToVersion)
            {
                await IncrementRepoVersion(db, repoId);
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
