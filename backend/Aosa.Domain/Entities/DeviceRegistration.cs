namespace Aosa.Domain.Entities;

public class DeviceRegistration
{
    public Guid Id { get; set; }
    public Guid DeviceId { get; set; }
    public string DeviceName { get; set; } = string.Empty;
    public string PinPublicSalt { get; set; } = string.Empty;
    public string PublicKey { get; set; } = string.Empty;
    public DateTime RegisteredAt { get; set; }
    public DateTime? LastSyncedAt { get; set; }
}
