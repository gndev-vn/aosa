using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using static Aosa.Api.Endpoints.EndpointHelpers;

namespace Aosa.Api.Endpoints;

public static class OtpEndpoints
{
    public static void MapOtpEndpoints(this WebApplication app)
    {
        var group = app.MapApiGroup("/api/v1/otp", "OTP Records");

        group.MapGet("/", async (
            [AsParameters] OtpQuery query,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var repoAccess = await HasRepoAccess(db, query.RepoId, user);
            if (!repoAccess) return Results.Forbid();

            var records = await db.OtpRecords
                .Where(r => r.RepoId == query.RepoId && r.DeletedAt == null)
                .OrderByDescending(r => r.UpdatedAt)
                .ToListAsync();

            return Results.Ok(new
            {
                items = records.Select(MapOtpToDto),
            });
        });

        group.MapPost("/", async (
            [FromBody] CreateOtpRequest request,
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
            [FromBody] UpdateOtpRequest request,
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
            [FromBody] DeleteOtpRequest request,
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
}

public record OtpQuery([FromQuery(Name = "repo_id")] Guid RepoId);

public class CreateOtpRequest
{
    public Guid Id { get; set; }
    public Guid RepoId { get; set; }
    [Required]
    public string EncryptedBlob { get; set; } = null!;
    public DateTime ClientTimestamp { get; set; }
}

public class UpdateOtpRequest
{
    [Required]
    public string EncryptedBlob { get; set; } = null!;
    [Range(1, int.MaxValue)]
    public int ExpectedVersion { get; set; }
    public DateTime ClientTimestamp { get; set; }
}

public class DeleteOtpRequest
{
    [Range(1, int.MaxValue)]
    public int ExpectedVersion { get; set; }
}
