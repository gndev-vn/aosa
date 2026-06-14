namespace Aosa.Domain.Entities;

public class OtpRecord
{
    public Guid Id { get; set; }
    public string EncryptedBlob { get; set; } = string.Empty;
    public int Version { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }

    public Guid RepoId { get; set; }
    public Guid DeviceId { get; set; }
}
