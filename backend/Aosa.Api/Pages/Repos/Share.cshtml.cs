using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Pages.Repos;

[Authorize]
public class ShareModel : PageModel
{
    private readonly AosaDbContext _db;

    public ShareModel(AosaDbContext db) => _db = db;

    public Guid RepoId { get; set; }
    public string RepoName { get; set; } = string.Empty;
    public List<MemberViewModel> Members { get; set; } = [];
    public string? Error { get; set; }
    public string? Success { get; set; }

    [BindProperty]
    public string Email { get; set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync(Guid repoId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var repo = await _db.Repos.FirstOrDefaultAsync(r => r.Id == repoId && r.OwnerId == userId);
        if (repo is null)
            return Forbid();

        RepoId = repoId;
        RepoName = repo.Name;
        await LoadMembers(repoId);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(Guid repoId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var repo = await _db.Repos.FirstOrDefaultAsync(r => r.Id == repoId && r.OwnerId == userId);
        if (repo is null)
            return Forbid();

        RepoId = repoId;
        RepoName = repo.Name;

        if (string.IsNullOrWhiteSpace(Email))
        {
            Error = "Enter a username.";
            await LoadMembers(repoId);
            return Page();
        }

        var targetUser = await _db.Users.FirstOrDefaultAsync(u => u.Username == Email.Trim());
        if (targetUser is null)
        {
            Error = "User not found.";
            await LoadMembers(repoId);
            return Page();
        }

        if (targetUser.Id == userId)
        {
            Error = "You cannot share a repo with yourself.";
            await LoadMembers(repoId);
            return Page();
        }

        var existing = await _db.RepoMemberships.AnyAsync(m =>
            m.RepoId == repoId && m.UserId == targetUser.Id);
        if (existing)
        {
            Error = "User is already a member.";
            await LoadMembers(repoId);
            return Page();
        }

        _db.RepoMemberships.Add(new RepoMembership
        {
            Id = Guid.NewGuid(),
            RepoId = repoId,
            UserId = targetUser.Id,
            Role = RepoRole.Admin,
            CreatedAt = DateTime.UtcNow
        });

        var syncMeta = new SyncMetadata
        {
            Id = Guid.NewGuid(),
            DeviceId = repoId,
            GlobalVersion = 0,
            LastSyncAt = DateTime.UtcNow
        };
        _db.SyncMetadatas.Add(syncMeta);

        await _db.SaveChangesAsync();
        Success = $"Shared with {targetUser.Username}.";
        Email = string.Empty;
        await LoadMembers(repoId);
        return Page();
    }

    private async Task LoadMembers(Guid repoId)
    {
        var owner = await _db.Repos
            .Where(r => r.Id == repoId)
            .Select(r => new MemberViewModel
            {
                UserId = r.OwnerId,
                Username = r.Owner!.Username,
                Role = "owner"
            })
            .FirstAsync();

        var members = await _db.RepoMemberships
            .Where(m => m.RepoId == repoId)
            .Include(m => m.User)
            .ToListAsync();

        Members =
        [
            owner,
            .. members.Select(m => new MemberViewModel
            {
                UserId = m.UserId,
                Username = m.User!.Username,
                Role = m.Role.ToString().ToLower()
            })
        ];
    }
}

public class MemberViewModel
{
    public Guid UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Role { get; set; } = "member";
}
