namespace Aosa.Domain.Entities;

public enum RepoRole { Viewer, Editor, Admin }

public class RepoMembership
{
    public Guid Id { get; set; }
    public Guid RepoId { get; set; }
    public Guid UserId { get; set; }
    public RepoRole Role { get; set; }
    public DateTime CreatedAt { get; set; }

    public Repo? Repo { get; set; }
    public User? User { get; set; }
}
