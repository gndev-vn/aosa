using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Aosa.Domain.Entities;
using Aosa.Infrastructure.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Aosa.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/v1/auth").WithTags("Authentication").RequireRateLimiting("Auth");

        group.MapPost("/signup", async (
            SignupRequest request,
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

            // create default repo
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

            var (jwt, refreshToken) = await GenerateUserTokens(user.Id, db, config);
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
            LoginRequest request,
            AosaDbContext db,
            IConfiguration config) =>
        {
            var user = await db.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
            if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Results.Unauthorized();

            user.LastLoginAt = DateTime.UtcNow;

            var (jwt, refreshToken) = await GenerateUserTokens(user.Id, db, config);
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
        }).RequireAuthorization();

        group.MapPost("/register", async (
            RegisterRequest request,
            AosaDbContext db,
            IConfiguration config) =>
        {
            var existing = await db.DeviceRegistrations
                .FirstOrDefaultAsync(d => d.DeviceId == request.DeviceId);

            if (existing is not null)
                return Results.Conflict(new { error = "device_already_registered" });

            var registration = new DeviceRegistration
            {
                Id = Guid.NewGuid(),
                DeviceId = request.DeviceId,
                DeviceName = request.DeviceName,
                PinPublicSalt = request.PinPublicSalt,
                PublicKey = request.PublicKey,
                RegisteredAt = DateTime.UtcNow
            };

            db.DeviceRegistrations.Add(registration);

            var syncMeta = new SyncMetadata
            {
                Id = Guid.NewGuid(),
                DeviceId = request.DeviceId,
                GlobalVersion = 0,
                LastSyncAt = DateTime.UtcNow
            };
            db.SyncMetadatas.Add(syncMeta);

            var (jwt, refreshToken) = await GenerateDeviceTokens(request.DeviceId, db, config);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/devices/{registration.Id}", new
            {
                device_token = jwt,
                refresh_token = refreshToken,
                server_version = 0
            });
        });

        group.MapPost("/refresh", async (
            RefreshRequest request,
            AosaDbContext db,
            IConfiguration config) =>
        {
            var tokenHash = HashToken(request.RefreshToken);
            var stored = await db.RefreshTokens.FirstOrDefaultAsync(rt => rt.TokenHash == tokenHash);

            if (stored is null || !stored.IsActive)
                return Results.Unauthorized();

            stored.RevokedAt = DateTime.UtcNow;

            if (stored.DeviceId.HasValue)
            {
                var (jwt, newRefreshToken) = await GenerateDeviceTokens(stored.DeviceId.Value, db, config);
                await db.SaveChangesAsync();
                return Results.Ok(new { device_token = jwt, refresh_token = newRefreshToken });
            }

            var (userJwt, userRefresh) = await GenerateUserTokens(stored.UserId, db, config);
            await db.SaveChangesAsync();
            return Results.Ok(new { token = userJwt, refresh_token = userRefresh });
        });
    }

    private static async Task<(string jwt, string refreshToken)> GenerateUserTokens(
        Guid userId, AosaDbContext db, IConfiguration config)
    {
        var (jwt, refreshToken) = GenerateTokenPair(userId.ToString(), db, config);

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

    private static async Task<(string jwt, string refreshToken)> GenerateDeviceTokens(
        Guid deviceId, AosaDbContext db, IConfiguration config)
    {
        var (jwt, refreshToken) = GenerateTokenPair(deviceId.ToString(), db, config);

        db.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = Guid.Empty,
            DeviceId = deviceId,
            TokenHash = HashToken(refreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        });

        return (jwt, refreshToken);
    }

    private static (string jwt, string refreshToken) GenerateTokenPair(
        string subject, AosaDbContext db, IConfiguration config)
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

public record SignupRequest(string Username, string Password);
public record LoginRequest(string Username, string Password);
public record RegisterRequest(Guid DeviceId, string DeviceName, string PinPublicSalt, string PublicKey);
public record RefreshRequest(string RefreshToken);
