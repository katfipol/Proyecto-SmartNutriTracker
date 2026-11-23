// BASE DEL SISTEMA (Equipo 1)
// SmartNutriTracker · Colegio Innovare
using Microsoft.EntityFrameworkCore;

namespace SmartNutriTracker.Api.Data;

/// <summary>
/// Contexto EF Core (Database-First). Es una clase PARCIAL: cada equipo declara sus DbSet
/// y la configuración de sus tablas en Modulos/EquipoN/ContextoDatos.cs.
/// </summary>
public partial class SmartNutriDbContext(DbContextOptions<SmartNutriDbContext> options) : DbContext(options)
{
    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        configurationBuilder.Properties<decimal>().HavePrecision(10, 2);
    }

    protected override void OnModelCreating(ModelBuilder mb)
    {
        ConfigurarEquipo1(mb);   // Seguridad
        ConfigurarEquipo2(mb);   // Perfil y reportes
        ConfigurarEquipo3(mb);   // Alimentos y menús
        ConfigurarEquipo4(mb);   // Hábitos
        ConfigurarEquipo5(mb);   // Recomendaciones
        ConfigurarEquipo6(mb);   // Alertas, notificaciones y citas
    }

    partial void ConfigurarEquipo1(ModelBuilder mb);
    partial void ConfigurarEquipo2(ModelBuilder mb);
    partial void ConfigurarEquipo3(ModelBuilder mb);
    partial void ConfigurarEquipo4(ModelBuilder mb);
    partial void ConfigurarEquipo5(ModelBuilder mb);
    partial void ConfigurarEquipo6(ModelBuilder mb);
}
