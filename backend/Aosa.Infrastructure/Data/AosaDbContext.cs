using Aosa.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Infrastructure.Data;

public class AosaDbContext : DbContext
{
    public AosaDbContext(DbContextOptions<AosaDbContext> options) : base(options) { }

    public DbSet<OtpRecord> OtpRecords => Set<OtpRecord>();
    public DbSet<DeviceRegistration> DeviceRegistrations => Set<DeviceRegistration>();
    public DbSet<SyncMetadata> SyncMetadatas => Set<SyncMetadata>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<OtpRecord>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.EncryptedBlob).IsRequired();
            entity.Property(e => e.Version).HasDefaultValue(1);
            entity.HasIndex(e => new { e.DeviceId, e.Version });
            entity.HasIndex(e => e.DeletedAt);
        });

        modelBuilder.Entity<DeviceRegistration>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.DeviceId).IsUnique();
        });

        modelBuilder.Entity<SyncMetadata>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.DeviceId).IsUnique();
        });
    }
}
