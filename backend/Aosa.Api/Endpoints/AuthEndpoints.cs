using System.ComponentModel.DataAnnotations;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Aosa.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/auth").WithTags("Authentication").RequireRateLimiting("Auth");

        group.MapPost("/signup", async (
            [FromBody] SignupRequest request,
            AosaDbContext db,
            IConfiguration config) =>
        {
            var existing = await db.Users.AnyAsync(u => u.Username == request.Username);
            if (existing)
                return Results.Conflict(new { error = "username_taken" });

            var user = new User
            {
                Id = Guid.NewGuid(),
                Username = request.Username,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                CreatedAt = DateTime.UtcNow,
                LastLoginAt = DateTime.UtcNow
            };

            db.Users.Add(user);

            var defaultRepo = new Repo
            {
                Id = Guid.NewGuid(),
                OwnerId = user.Id,
                Name = "Default",
                IsDefault = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            db.Repos.Add(defaultRepo);

            var (jwt, refreshToken) = GenerateUserTokens(user.Id, db, config);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/users/{user.Id}", new
            {
                user_id = user.Id,
                token = jwt,
                refresh_token = refreshToken,
                default_repo_id = defaultRepo.Id
            });
        });

        group.MapPost("/login", async (
            [FromBody] LoginRequest request,
            AosaDbContext db,
            IConfiguration config) =>
        {
            var user = await db.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
            if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Results.Unauthorized();

            user.LastLoginAt = DateTime.UtcNow;

            var (jwt, refreshToken) = GenerateUserTokens(user.Id, db, config);
            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                user_id = user.Id,
                token = jwt,
                refresh_token = refreshToken
            });
        });

        group.MapGet("/me", async (
            ClaimsPrincipal user,
            AosaDbContext db) =>
        {
            var userIdStr = user.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
            if (userIdStr is null || !Guid.TryParse(userIdStr, out var userId))
                return Results.Unauthorized();

            var dbUser = await db.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (dbUser is null)
                return Results.NotFound();

            return Results.Ok(new
            {
                user_id = dbUser.Id,
                username = dbUser.Username,
                created_at = dbUser.CreatedAt
            });
        }).RequireAuthorization("Jwt");

        group.MapPost("/refresh", async (
            [FromBody] RefreshRequest request,
            AosaDbContext db,
            IConfiguration config) =>
        {
            var tokenHash = HashToken(request.RefreshToken);
            var stored = await db.RefreshTokens.FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash);

            if (stored is null || !stored.IsActive)
                return Results.Unauthorized();

            stored.RevokedAt = DateTime.UtcNow;

            var (jwt, newRefreshToken) = GenerateUserTokens(stored.UserId, db, config);
            await db.SaveChangesAsync();
            return Results.Ok(new { token = jwt, refresh_token = newRefreshToken });
        });
    }

    private static (string jwt, string refreshToken) GenerateUserTokens(
        Guid userId, AosaDbContext db, IConfiguration config)
    {
        var (jwt, refreshToken) = GenerateTokenPair(userId.ToString(), config);

        db.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            TokenHash = HashToken(refreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        });

        return (jwt, refreshToken);
    }

    private static (string jwt, string refreshToken) GenerateTokenPair(
        string subject, IConfiguration config)
    {
        var jwtSection = config.GetSection("Jwt");
        var key = Encoding.UTF8.GetBytes(jwtSection["Key"]!);
        var issuer = jwtSection["Issuer"]!;
        var audience = jwtSection["Audience"]!;
        var expireMinutes = int.Parse(jwtSection["ExpireMinutes"] ?? "60");

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, subject),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        };

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(expireMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = new SigningCredentials(
                new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256)
        };

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.WriteToken(handler.CreateToken(tokenDescriptor));

        var refreshToken = GenerateSecureToken();
        return (jwt, refreshToken);
    }

    private static string GenerateSecureToken()
    {
        var bytes = new byte[64];
        RandomNumberGenerator.Fill(bytes);
        return Convert.ToBase64String(bytes);
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToBase64String(bytes);
    }
}

public class SignupRequest
{
    [Required, MinLength(3), MaxLength(32)]
    public string Username { get; set; } = null!;
    [Required, MinLength(8), MaxLength(128)]
    public string Password { get; set; } = null!;
}

public class LoginRequest
{
    [Required]
    public string Username { get; set; } = null!;
    [Required]
    public string Password { get; set; } = null!;
}

public class RefreshRequest
{
    [Required]
    public string RefreshToken { get; set; } = null!;
}
