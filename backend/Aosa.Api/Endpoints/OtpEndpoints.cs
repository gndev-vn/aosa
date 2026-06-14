using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class OtpEndpoints
{
    public static void MapOtpEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/otp")
            .WithTags("OTP Records")
            .RequireAuthorization()
            .RequireRateLimiting("Api");

        group.MapGet("/", async (
            [AsParameters] OtpQuery query,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var records = await db.OtpRecords
                .Where(r => r.RepoId == query.RepoId && r.DeletedAt == null)
                .OrderByDescending(r => r.UpdatedAt)
                .ToListAsync();

            return Results.Ok(new
            {
                items = records.Select(MapToDto),
            });
        });

        group.MapPost("/", async (
            CreateOtpRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var repoAccess = await HasRepoAccess(db, request.RepoId, user);
            if (!repoAccess) return Results.Forbid();

            var record = new OtpRecord
            {
                Id = request.Id,
                EncryptedBlob = request.EncryptedBlob,
                Version = 1,
                RepoId = request.RepoId,
                DeviceId = GetDeviceId(user),
                CreatedAt = request.ClientTimestamp,
                UpdatedAt = request.ClientTimestamp,
            };

            db.OtpRecords.Add(record);
            await IncrementRepoVersion(db, request.RepoId);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/otp/{record.Id}", new
            {
                id = record.Id,
                version = record.Version,
                repo_id = record.RepoId,
                created_at = record.CreatedAt
            });
        });

        group.MapPut("/{id:guid}", async (
            Guid id,
            UpdateOtpRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var record = await db.OtpRecords.FindAsync(id);
            if (record is null)
                return Results.NotFound(new { error = "not_found" });

            var repoAccess = await HasRepoAccess(db, record.RepoId, user);
            if (!repoAccess) return Results.Forbid();

            if (request.ExpectedVersion != record.Version)
            {
                return Results.Conflict(new
                {
                    error = "conflict",
                    current_version = record.Version,
                    message = "Record has been updated by another device. Fetch latest and re-apply."
                });
            }

            record.EncryptedBlob = request.EncryptedBlob;
            record.Version++;
            record.UpdatedAt = request.ClientTimestamp;

            await IncrementRepoVersion(db, record.RepoId);
            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                id = record.Id,
                version = record.Version,
                updated_at = record.UpdatedAt
            });
        });

        group.MapDelete("/{id:guid}", async (
            Guid id,
            DeleteOtpRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var record = await db.OtpRecords.FindAsync(id);
            if (record is null)
                return Results.NotFound(new { error = "not_found" });

            var repoAccess = await HasRepoAccess(db, record.RepoId, user);
            if (!repoAccess) return Results.Forbid();

            if (request.ExpectedVersion != record.Version)
            {
                return Results.Conflict(new
                {
                    error = "conflict",
                    current_version = record.Version
                });
            }

            record.DeletedAt = DateTime.UtcNow;
            record.Version++;

            await IncrementRepoVersion(db, record.RepoId);
            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                id = record.Id,
                deleted_at = record.DeletedAt,
                version = record.Version
            });
        });
    }

    private static async Task<bool> HasRepoAccess(AosaDbContext db, Guid repoId, ClaimsPrincipal user)
    {
        var userId = GetUserId(user);
        if (userId == Guid.Empty) return false;

        var repo = await db.Repos.FindAsync(repoId);
        if (repo is null) return false;
        if (repo.OwnerId == userId) return true;

        return await db.RepoMemberships.AnyAsync(m =>
            m.RepoId == repoId && m.UserId == userId);
    }

    private static async Task IncrementRepoVersion(AosaDbContext db, Guid repoId)
    {
        var meta = await db.SyncMetadatas.FirstOrDefaultAsync(m => m.DeviceId == repoId);
        if (meta is not null)
            meta.GlobalVersion++;
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? user.FindFirstValue("sub");
        if (sub is null) return Guid.Empty;
        return Guid.TryParse(sub, out var id) ? id : Guid.Empty;
    }

    private static Guid GetDeviceId(ClaimsPrincipal user) => Guid.Empty;

    private static object MapToDto(OtpRecord r) => new
    {
        id = r.Id,
        encrypted_blob = r.EncryptedBlob,
        version = r.Version,
        repo_id = r.RepoId,
        created_at = r.CreatedAt,
        updated_at = r.UpdatedAt,
        deleted_at = r.DeletedAt
    };
}

public record OtpQuery(Guid RepoId);
public record CreateOtpRequest(Guid Id, Guid RepoId, string EncryptedBlob, DateTime ClientTimestamp);
public record UpdateOtpRequest(string EncryptedBlob, int ExpectedVersion, DateTime ClientTimestamp);
public record DeleteOtpRequest(int ExpectedVersion);
