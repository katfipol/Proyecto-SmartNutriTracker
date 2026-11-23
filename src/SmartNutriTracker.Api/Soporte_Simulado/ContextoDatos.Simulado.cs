// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// En el sistema integrado, estas tablas las agregan los ContextoDatos.cs de los Equipos 2 y 3.
using Microsoft.EntityFrameworkCore;
using SmartNutriTracker.Api.Data.Entities;

namespace SmartNutriTracker.Api.Data;

/// <summary>Tablas mínimas de los Equipos 2 y 3 que necesita el Equipo 4.</summary>
public partial class SmartNutriDbContext
{
    public DbSet<Estudiante> Estudiantes => Set<Estudiante>();
    public DbSet<CategoriaAlimento> CategoriasAlimento => Set<CategoriaAlimento>();
    public DbSet<TipoComida> TiposComida => Set<TipoComida>();
    public DbSet<Alimento> Alimentos => Set<Alimento>();

    partial void ConfigurarEquipo2(ModelBuilder mb)
    {
        mb.Entity<Estudiante>(e =>
        {
            e.ToTable("Estudiantes");
            e.Ignore(x => x.NombreCompleto);
            e.Property(x => x.FactorActividad).HasPrecision(4, 3);
        });
    }

    partial void ConfigurarEquipo3(ModelBuilder mb)
    {
        mb.Entity<CategoriaAlimento>().ToTable("CategoriasAlimento");
        mb.Entity<TipoComida>().ToTable("TiposComida");
        mb.Entity<Alimento>().ToTable("Alimentos");
    }
}
