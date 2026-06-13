namespace Aosa.Domain.Entities;

public class SyncMetadata
{
    public Guid Id { get; set; }
    public Guid DeviceId { get; set; }
    public long GlobalVersion { get; set; }
    public DateTime LastSyncAt { get; set; }
}
