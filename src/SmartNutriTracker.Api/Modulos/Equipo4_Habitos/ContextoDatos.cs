using Microsoft.EntityFrameworkCore;
using SmartNutriTracker.Api.Data.Entities;

namespace SmartNutriTracker.Api.Data;

public partial class SmartNutriDbContext
{
    public DbSet<RegistroConsumo> RegistrosConsumo => Set<RegistroConsumo>();
    public DbSet<RegistroHabito> RegistrosHabitos => Set<RegistroHabito>();

    partial void ConfigurarEquipo4(ModelBuilder mb)
    {
        mb.Entity<RegistroConsumo>().ToTable("RegistrosConsumo");
        mb.Entity<RegistroHabito>().ToTable("RegistrosHabitos");
    }
}
