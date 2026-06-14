using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Pages.Repos;

[Authorize]
public class CreateModel : PageModel
{
    private readonly AosaDbContext _db;

    public CreateModel(AosaDbContext db) => _db = db;

    [BindProperty]
    public string Name { get; set; } = string.Empty;

    public string? Error { get; set; }

    public async Task<IActionResult> OnPostAsync()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        if (string.IsNullOrWhiteSpace(Name))
        {
            Error = "Repo name is required.";
            return Page();
        }

        var repoCount = await _db.Repos.CountAsync(r => r.OwnerId == userId && !r.IsDefault);
        if (repoCount >= 10)
        {
            Error = "Maximum of 10 custom repos reached.";
            return Page();
        }

        var repo = new Repo
        {
            Id = Guid.NewGuid(),
            OwnerId = userId,
            Name = Name.Trim(),
            IsDefault = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Repos.Add(repo);
        await _db.SaveChangesAsync();

        return Redirect("/repos");
    }
}
