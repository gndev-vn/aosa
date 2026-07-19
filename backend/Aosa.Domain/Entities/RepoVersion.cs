namespace Aosa.Domain.Entities;

public class RepoVersion
{
    public Guid Id { get; set; }
    public Guid RepoId { get; set; }
    public long GlobalVersion { get; set; }
    public DateTime LastUpdatedAt { get; set; }
}
