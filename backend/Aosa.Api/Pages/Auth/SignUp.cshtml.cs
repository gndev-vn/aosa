using System.Security.Claims;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Api.Pages.Auth;

public class SignUpModel : PageModel
{
    private readonly AosaDbContext _db;

    public SignUpModel(AosaDbContext db) => _db = db;

    [BindProperty]
    public string Username { get; set; } = string.Empty;

    [BindProperty]
    public string Password { get; set; } = string.Empty;

    [BindProperty]
    public string ConfirmPassword { get; set; } = string.Empty;

    public string? Error { get; set; }

    public async Task<IActionResult> OnPostAsync()
    {
        if (Password != ConfirmPassword)
        {
            Error = "Passwords do not match.";
            return Page();
        }

        if (Username.Length < 3)
        {
            Error = "Username must be at least 3 characters.";
            return Page();
        }

        if (Password.Length < 6)
        {
            Error = "Password must be at least 6 characters.";
            return Page();
        }

        var existing = await _db.Users.AnyAsync(u => u.Username == Username);
        if (existing)
        {
            Error = "Username is already taken.";
            return Page();
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(Password),
            CreatedAt = DateTime.UtcNow,
            LastLoginAt = DateTime.UtcNow
        };

        _db.Users.Add(user);

        var defaultRepo = new Repo
        {
            Id = Guid.NewGuid(),
            OwnerId = user.Id,
            Name = "Default",
            IsDefault = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Repos.Add(defaultRepo);
        await _db.SaveChangesAsync();

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
        };

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties { IsPersistent = true });

        return Redirect("/repos");
    }
}
