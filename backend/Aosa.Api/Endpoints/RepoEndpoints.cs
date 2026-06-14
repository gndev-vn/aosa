using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class RepoEndpoints
{
    public static void MapRepoEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/repos")
            .WithTags("Repos")
            .RequireAuthorization()
            .RequireRateLimiting("Api");

        group.MapGet("/", async (AosaDbContext db, ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);
            var owned = await db.Repos.Where(r => r.OwnerId == userId).ToListAsync();
            var sharedIds = await db.RepoMemberships
                .Where(m => m.UserId == userId)
                .Select(m => m.RepoId)
                .ToListAsync();
            var shared = await db.Repos.Where(r => sharedIds.Contains(r.Id)).ToListAsync();

            var all = owned.Concat(shared).DistinctBy(r => r.Id).ToList();
            return Results.Ok(all.Select(r => new
            {
                id = r.Id,
                owner_id = r.OwnerId,
                name = r.Name,
                is_default = r.IsDefault,
                created_at = r.CreatedAt,
                shared = r.OwnerId != userId
            }));
        });

        group.MapPost("/", async (
            CreateRepoRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);

            var repoCount = await db.Repos.CountAsync(r => r.OwnerId == userId && !r.IsDefault);
            if (repoCount >= 10)
                return Results.BadRequest(new { error = "max_repos_reached", message = "Maximum 10 custom repos allowed" });

            var repo = new Repo
            {
                Id = Guid.NewGuid(),
                OwnerId = userId,
                Name = request.Name,
                IsDefault = false,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            db.Repos.Add(repo);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/repos/{repo.Id}", new
            {
                id = repo.Id,
                name = repo.Name
            });
        });

        group.MapPut("/{id:guid}", async (
            Guid id,
            UpdateRepoRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);
            var repo = await db.Repos.FirstOrDefaultAsync(r => r.Id == id && r.OwnerId == userId);
            if (repo is null)
                return Results.NotFound(new { error = "not_found" });

            repo.Name = request.Name;
            repo.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();

            return Results.Ok(new { id = repo.Id, name = repo.Name });
        });

        group.MapDelete("/{id:guid}", async (
            Guid id,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);
            var repo = await db.Repos.FirstOrDefaultAsync(r => r.Id == id && r.OwnerId == userId);
            if (repo is null)
                return Results.NotFound(new { error = "not_found" });

            if (repo.IsDefault)
                return Results.BadRequest(new { error = "cannot_delete_default" });

            var memberships = await db.RepoMemberships.Where(m => m.RepoId == id).ToListAsync();
            db.RepoMemberships.RemoveRange(memberships);

            var records = await db.OtpRecords.Where(o => o.RepoId == id).ToListAsync();
            db.OtpRecords.RemoveRange(records);

            db.Repos.Remove(repo);
            await db.SaveChangesAsync();

            return Results.Ok(new { deleted = true });
        });

        group.MapPost("/{id:guid}/share", async (
            Guid id,
            ShareRepoRequest request,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);
            var repo = await db.Repos.FirstOrDefaultAsync(r => r.Id == id && r.OwnerId == userId);
            if (repo is null)
                return Results.NotFound(new { error = "not_found" });

            var targetUser = await db.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
            if (targetUser is null)
                return Results.NotFound(new { error = "user_not_found" });

            if (targetUser.Id == userId)
                return Results.BadRequest(new { error = "cannot_share_with_self" });

            var existing = await db.RepoMemberships.AnyAsync(m => m.RepoId == id && m.UserId == targetUser.Id);
            if (existing)
                return Results.Conflict(new { error = "already_shared" });

            db.RepoMemberships.Add(new RepoMembership
            {
                Id = Guid.NewGuid(),
                RepoId = id,
                UserId = targetUser.Id,
                Role = request.Role,
                CreatedAt = DateTime.UtcNow
            });

            await db.SaveChangesAsync();

            // create sync metadata for the shared user
            var hasMeta = await db.SyncMetadatas.AnyAsync(m => m.DeviceId == targetUser.Id);
            if (!hasMeta)
            {
                db.SyncMetadatas.Add(new SyncMetadata
                {
                    Id = Guid.NewGuid(),
                    DeviceId = targetUser.Id,
                    GlobalVersion = 0,
                    LastSyncAt = DateTime.UtcNow
                });
                await db.SaveChangesAsync();
            }

            return Results.Ok(new { shared = true, username = request.Username, role = request.Role.ToString() });
        });

        group.MapDelete("/{id:guid}/share/{userId:guid}", async (
            Guid id,
            Guid targetUserId,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);
            var repo = await db.Repos.FirstOrDefaultAsync(r => r.Id == id && r.OwnerId == userId);
            if (repo is null)
                return Results.NotFound(new { error = "not_found" });

            var membership = await db.RepoMemberships
                .FirstOrDefaultAsync(m => m.RepoId == id && m.UserId == targetUserId);
            if (membership is null)
                return Results.NotFound(new { error = "membership_not_found" });

            db.RepoMemberships.Remove(membership);
            await db.SaveChangesAsync();

            return Results.Ok(new { removed = true });
        });

        group.MapGet("/{id:guid}/members", async (
            Guid id,
            AosaDbContext db,
            ClaimsPrincipal user) =>
        {
            var userId = GetUserId(user);
            var repo = await db.Repos.FirstOrDefaultAsync(r => r.Id == id && r.OwnerId == userId);
            if (repo is null)
                return Results.NotFound(new { error = "not_found" });

            var members = await db.RepoMemberships
                .Where(m => m.RepoId == id)
                .Join(db.Users, m => m.UserId, u => u.Id, (m, u) => new
                {
                    user_id = u.Id,
                    username = u.Username,
                    role = m.Role.ToString(),
                    since = m.CreatedAt
                })
                .ToListAsync();

            return Results.Ok(members);
        });
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? user.FindFirstValue("sub");
        return Guid.Parse(sub!);
    }
}

public record CreateRepoRequest(string Name);
public record UpdateRepoRequest(string Name);
public record ShareRepoRequest(string Username, RepoRole Role);
