using Aosa.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Aosa.Infrastructure.Data;

public class AosaDbContext : DbContext
{
    public AosaDbContext(DbContextOptions<AosaDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Repo> Repos => Set<Repo>();
    public DbSet<RepoMembership> RepoMemberships => Set<RepoMembership>();
    public DbSet<OtpRecord> OtpRecords => Set<OtpRecord>();
    public DbSet<DeviceRegistration> DeviceRegistrations => Set<DeviceRegistration>();
    public DbSet<SyncMetadata> SyncMetadatas => Set<SyncMetadata>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Username).IsUnique();
        });

        modelBuilder.Entity<Repo>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.OwnerId);
            entity.HasOne(e => e.Owner)
                .WithMany(u => u.OwnedRepos)
                .HasForeignKey(e => e.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<RepoMembership>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => new { e.RepoId, e.UserId }).IsUnique();
            entity.HasOne(e => e.Repo)
                .WithMany(r => r.Memberships)
                .HasForeignKey(e => e.RepoId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(e => e.User)
                .WithMany(u => u.Memberships)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OtpRecord>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.EncryptedBlob).IsRequired();
            entity.Property(e => e.Version).HasDefaultValue(1);
            entity.HasIndex(e => new { e.RepoId, e.Version });
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

        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.TokenHash);
            entity.HasIndex(e => e.UserId);
        });
    }
}
