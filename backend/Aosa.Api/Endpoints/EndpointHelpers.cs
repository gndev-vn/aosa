using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Endpoints;

public static class EndpointHelpers
{
    public static Guid GetUserId(ClaimsPrincipal user)
    {
        var sub = user.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? user.FindFirstValue("sub");
        if (sub is null) return Guid.Empty;
        return Guid.TryParse(sub, out var id) ? id : Guid.Empty;
    }

    public static async Task<bool> HasRepoAccess(AosaDbContext db, Guid repoId, ClaimsPrincipal user)
    {
        var userId = GetUserId(user);
        if (userId == Guid.Empty) return false;

        var repo = await db.Repos.FindAsync(repoId);
        if (repo is null) return false;
        if (repo.OwnerId == userId) return true;

        return await db.RepoMemberships.AnyAsync(m =>
            m.RepoId == repoId && m.UserId == userId);
    }

    public static async Task IncrementRepoVersion(AosaDbContext db, Guid repoId)
    {
        var repoVersion = await db.RepoVersions.FirstOrDefaultAsync(rv => rv.RepoId == repoId);
        if (repoVersion is not null)
        {
            repoVersion.GlobalVersion++;
            repoVersion.LastUpdatedAt = DateTime.UtcNow;
        }
        else
        {
            db.RepoVersions.Add(new RepoVersion
            {
                Id = Guid.NewGuid(),
                RepoId = repoId,
                GlobalVersion = 1,
                LastUpdatedAt = DateTime.UtcNow
            });
        }
    }

    public static object MapOtpToDto(OtpRecord r) => new
    {
        id = r.Id,
        encrypted_blob = r.EncryptedBlob,
        version = r.Version,
        repo_id = r.RepoId,
        created_at = r.CreatedAt,
        updated_at = r.UpdatedAt,
        deleted_at = r.DeletedAt
    };

    public static RouteGroupBuilder MapApiGroup(this WebApplication app, string path, string tag)
    {
        return app.MapGroup(path)
            .WithTags(tag)
            .RequireAuthorization("Jwt")
            .RequireRateLimiting("Api");
    }
}
