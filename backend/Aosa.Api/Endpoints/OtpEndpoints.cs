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
            .RequireAuthorization();

        group.MapGet("/", async (AosaDbContext db) =>
        {
            var records = await db.OtpRecords
                .Where(r => r.DeletedAt == null)
                .OrderByDescending(r => r.UpdatedAt)
                .ToListAsync();

            var serverVersion = await db.SyncMetadatas
                .Select(m => m.GlobalVersion)
                .FirstOrDefaultAsync();

            return Results.Ok(new
            {
                items = records.Select(MapToDto),
                server_version = serverVersion
            });
        });

        group.MapPost("/", async (
            CreateOtpRequest request,
            AosaDbContext db) =>
        {
            var record = new OtpRecord
            {
                Id = request.Id,
                EncryptedBlob = request.EncryptedBlob,
                Version = 1,
                CreatedAt = request.ClientTimestamp,
                UpdatedAt = request.ClientTimestamp,
                DeviceId = Guid.Empty // Will come from JWT
            };

            db.OtpRecords.Add(record);
            await IncrementGlobalVersion(db);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/otp/{record.Id}", new
            {
                id = record.Id,
                version = record.Version,
                created_at = record.CreatedAt
            });
        });

        group.MapPut("/{id:guid}", async (
            Guid id,
            UpdateOtpRequest request,
            AosaDbContext db) =>
        {
            var record = await db.OtpRecords.FindAsync(id);
            if (record is null)
                return Results.NotFound(new { error = "not_found" });

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

            await IncrementGlobalVersion(db);
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
            AosaDbContext db) =>
        {
            var record = await db.OtpRecords.FindAsync(id);
            if (record is null)
                return Results.NotFound(new { error = "not_found" });

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

            await IncrementGlobalVersion(db);
            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                id = record.Id,
                deleted_at = record.DeletedAt,
                version = record.Version
            });
        });
    }

    private static async Task IncrementGlobalVersion(AosaDbContext db)
    {
        var meta = await db.SyncMetadatas.FirstOrDefaultAsync();
        if (meta is not null)
            meta.GlobalVersion++;
    }

    private static object MapToDto(OtpRecord r) => new
    {
        id = r.Id,
        encrypted_blob = r.EncryptedBlob,
        version = r.Version,
        created_at = r.CreatedAt,
        updated_at = r.UpdatedAt,
        deleted_at = r.DeletedAt
    };
}

public record CreateOtpRequest(
    Guid Id,
    string EncryptedBlob,
    DateTime ClientTimestamp
);

public record UpdateOtpRequest(
    string EncryptedBlob,
    int ExpectedVersion,
    DateTime ClientTimestamp
);

public record DeleteOtpRequest(int ExpectedVersion);
