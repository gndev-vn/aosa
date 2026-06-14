using System.Security.Claims;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Pages.Repos;

[Authorize]
public class IndexModel : PageModel
{
    private readonly AosaDbContext _db;

    public IndexModel(AosaDbContext db) => _db = db;

    public List<RepoViewModel> Repos { get; set; } = [];

    public async Task OnGetAsync()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var owned = await _db.Repos
            .Where(r => r.OwnerId == userId)
            .Select(r => new RepoViewModel
            {
                Id = r.Id,
                Name = r.Name,
                IsDefault = r.IsDefault,
                Role = "owner",
                MemberCount = _db.RepoMemberships.Count(m => m.RepoId == r.Id)
            })
            .ToListAsync();

        var memberData = await _db.RepoMemberships
            .Where(m => m.UserId == userId)
            .Include(m => m.Repo)
            .ToListAsync();

        var member = memberData.Select(m => new RepoViewModel
        {
            Id = m.Repo!.Id,
            Name = m.Repo.Name,
            IsDefault = false,
            Role = m.Role.ToString().ToLower(),
            MemberCount = _db.RepoMemberships.Count(r => r.RepoId == m.RepoId)
        }).ToList();

        Repos = [.. owned, .. member];
    }
}

public class RepoViewModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public string Role { get; set; } = "member";
    public int MemberCount { get; set; }
}
