namespace Aosa.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }

    public ICollection<Repo>? OwnedRepos { get; set; }
    public ICollection<RepoMembership>? Memberships { get; set; }
}
