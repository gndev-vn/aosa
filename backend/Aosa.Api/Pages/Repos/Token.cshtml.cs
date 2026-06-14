using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Aosa.Api.Pages.Repos;

[Authorize]
public class TokenModel : PageModel
{
    private readonly AosaDbContext _db;
    private readonly IConfiguration _config;

    public TokenModel(AosaDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public string? Token { get; set; }
    public string RepoName { get; set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync(Guid repoId)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var repo = await _db.Repos.FirstOrDefaultAsync(r =>
            r.Id == repoId && (r.OwnerId == userId ||
                _db.RepoMemberships.Any(m => m.RepoId == r.Id && m.UserId == userId)));
        if (repo is null)
            return Forbid();

        RepoName = repo.Name;

        var jwtSection = _config.GetSection("Jwt");
        var key = Encoding.UTF8.GetBytes(jwtSection["Key"]!);
        var issuer = jwtSection["Issuer"]!;
        var audience = jwtSection["Audience"]!;

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("repo_id", repoId.ToString()),
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddYears(1),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256)
        };

        var handler = new JwtSecurityTokenHandler();
        Token = handler.WriteToken(handler.CreateToken(tokenDescriptor));

        return Page();
    }
}
