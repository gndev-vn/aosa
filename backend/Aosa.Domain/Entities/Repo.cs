namespace Aosa.Domain.Entities;

public class Repo
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User? Owner { get; set; }
    public ICollection<RepoMembership>? Memberships { get; set; }
}
