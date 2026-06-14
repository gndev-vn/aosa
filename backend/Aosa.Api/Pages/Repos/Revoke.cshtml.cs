using System.Security.Claims;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Pages.Repos;

[Authorize]
public class RevokeModel : PageModel
{
    private readonly AosaDbContext _db;

    public RevokeModel(AosaDbContext db) => _db = db;

    [BindProperty]
    public Guid UserId { get; set; }

    public async Task<IActionResult> OnPostAsync(Guid repoId)
    {
        var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var repo = await _db.Repos.FirstOrDefaultAsync(r => r.Id == repoId && r.OwnerId == currentUserId);
        if (repo is null)
            return Forbid();

        var membership = await _db.RepoMemberships
            .FirstOrDefaultAsync(m => m.RepoId == repoId && m.UserId == UserId);
        if (membership is not null)
        {
            _db.RepoMemberships.Remove(membership);
            await _db.SaveChangesAsync();
        }

        return Redirect($"/repos/{repoId}/share");
    }
}
