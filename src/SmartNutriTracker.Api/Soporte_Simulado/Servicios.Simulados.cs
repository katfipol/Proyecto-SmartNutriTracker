// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// Las interfaces tienen el mismo nombre y las mismas firmas que usa HabitosService,
// pero solo con los métodos que necesita el Equipo 4. Las implementaciones son simples:
//   - IAccesoService     → reemplaza al Equipo 1 (permisos por rol)
//   - IAuditoriaService  → reemplaza al Equipo 1 (aquí solo escribe en la consola)
//   - INutricionService  → reemplaza al Equipo 5 (objetivo calórico con Mifflin-St Jeor)
//   - IAlertasService    → reemplaza al Equipo 6 (aquí solo escribe en la consola)
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using SmartNutriTracker.Api.Common;
using SmartNutriTracker.Api.Data;
using SmartNutriTracker.Api.Data.Entities;
using SmartNutriTracker.Api.Domain;

namespace SmartNutriTracker.Api.Services;

// ======================= Usuarios de prueba =======================

public sealed record UsuarioPrueba(int Id, string Nombre, string Correo, string Rol, string? Curso);

/// <summary>Cuentas de prueba. Los estudiantes inician sesión con el correo guardado en la tabla Estudiantes.</summary>
public static class UsuariosPrueba
{
    public const string Password = "Innovare2026!";

    /// <summary>Para no repetir ids, el id de usuario de un estudiante es 1000 + su id de estudiante.</summary>
    public const int OffsetEstudiantes = 1000;

    public static readonly IReadOnlyList<UsuarioPrueba> Personal =
    [
        new(2, "Lic. María Rojas", "nutricion@innovare.edu.bo", Roles.Nutricionista, null),
        new(3, "Prof. Jorge Vargas", "jvargas@innovare.edu.bo", Roles.Docente, "5to Secundaria A")
    ];
}

// ======================= Acceso (Equipo 1) =======================

public interface IAccesoService
{
    IQueryable<Estudiante> EstudiantesVisibles();
    Task VerificarEstudianteAsync(int estudianteId, CancellationToken ct = default);
}

public class AccesoServiceSimulado(SmartNutriDbContext db, IHttpContextAccessor accessor) : IAccesoService
{
    private ClaimsPrincipal Usuario =>
        accessor.HttpContext?.User ?? throw new NoAutorizadoException("No hay un usuario autenticado.");

    /// <summary>Estudiante: solo él mismo. Docente: los de su curso. Nutricionista: todos.</summary>
    public IQueryable<Estudiante> EstudiantesVisibles()
    {
        var usuario = Usuario;
        var consulta = db.Estudiantes.Where(e => e.Activo);
        var rol = usuario.ObtenerRol();

        if (rol == Roles.Estudiante)
        {
            var estudianteId = int.TryParse(usuario.FindFirstValue("estudianteId"), out var id) ? id : 0;
            return consulta.Where(e => e.Id == estudianteId);
        }

        if (rol == Roles.Docente)
        {
            var usuarioId = usuario.ObtenerUsuarioId();
            var curso = UsuariosPrueba.Personal.FirstOrDefault(p => p.Id == usuarioId)?.Curso ?? string.Empty;
            return consulta.Where(e => e.Curso == curso);
        }

        return consulta;
    }

    public async Task VerificarEstudianteAsync(int estudianteId, CancellationToken ct = default)
    {
        if (await EstudiantesVisibles().AnyAsync(e => e.Id == estudianteId, ct)) return;
        if (await db.Estudiantes.AnyAsync(e => e.Id == estudianteId, ct))
            throw new AccesoDenegadoException("No tiene permiso para acceder a los datos de este estudiante.");
        throw new NoEncontradoException($"Estudiante {estudianteId} no encontrado.");
    }
}

// ======================= Auditoría (Equipo 1) =======================

public interface IAuditoriaService
{
    Task RegistrarAsync(string accion, string entidad, object? entidadId = null, string? detalle = null,
        int? usuarioId = null, CancellationToken ct = default);
}

public class AuditoriaServiceSimulado(ILogger<AuditoriaServiceSimulado> logger) : IAuditoriaService
{
    public Task RegistrarAsync(string accion, string entidad, object? entidadId = null, string? detalle = null,
        int? usuarioId = null, CancellationToken ct = default)
    {
        logger.LogInformation("[AUDITORÍA simulada] {Accion} · {Entidad} {EntidadId} · {Detalle}", accion, entidad, entidadId, detalle);
        return Task.CompletedTask;
    }
}

// ======================= Cálculo nutricional (Equipo 5) =======================

public interface INutricionService
{
    Task<Estudiante> CargarEstudianteAsync(int estudianteId, CancellationToken ct = default);
    Task<ResultadoCalculo> CalcularEstudianteAsync(Estudiante estudiante, DateOnly fecha, string? objetivo = null, CancellationToken ct = default);
}

public class NutricionServiceSimulado(SmartNutriDbContext db) : INutricionService
{
    private const decimal CaloriasMinimas = 1400m;

    public async Task<Estudiante> CargarEstudianteAsync(int estudianteId, CancellationToken ct = default) =>
        await db.Estudiantes.AsNoTracking().FirstOrDefaultAsync(e => e.Id == estudianteId, ct)
        ?? throw new NoEncontradoException($"Estudiante {estudianteId} no encontrado.");

    /// <summary>
    /// Mifflin-St Jeor: TMB = 10·peso + 6,25·altura − 5·edad + (5 hombres / −161 mujeres).
    /// Gasto total = TMB × factor de actividad. Objetivo = gasto total ± ajuste del objetivo.
    /// </summary>
    public Task<ResultadoCalculo> CalcularEstudianteAsync(Estudiante estudiante, DateOnly fecha, string? objetivo = null, CancellationToken ct = default)
    {
        var edad = fecha.Year - estudiante.FechaNacimiento.Year;
        if (fecha < estudiante.FechaNacimiento.AddYears(edad)) edad--;

        var alturaM = estudiante.AlturaCm / 100m;
        var imc = alturaM > 0 ? Math.Round(estudiante.PesoKg / (alturaM * alturaM), 1) : 0m;
        var tmb = 10m * estudiante.PesoKg + 6.25m * estudiante.AlturaCm - 5m * edad + (estudiante.Sexo == "M" ? 5m : -161m);
        var gastoTotal = tmb * estudiante.FactorActividad;
        var caloriasObjetivo = Math.Max(CaloriasMinimas, Math.Round(gastoTotal * (1 + estudiante.AjusteObjetivo / 100m), 0));

        var categoria = imc < 18.5m ? "Bajo peso" : imc < 25m ? "Normal" : imc < 30m ? "Sobrepeso" : "Obesidad";

        return Task.FromResult(new ResultadoCalculo(imc, categoria, Math.Round(tmb, 1), estudiante.FactorActividad,
            Math.Round(gastoTotal, 0), caloriasObjetivo));
    }
}

// ======================= Alertas (Equipo 6) =======================

public interface IAlertasService
{
    Task<int> EvaluarDiaAsync(int estudianteId, DateOnly fecha, bool diaCerrado, CancellationToken ct = default);
}

public class AlertasServiceSimulado(ILogger<AlertasServiceSimulado> logger) : IAlertasService
{
    public Task<int> EvaluarDiaAsync(int estudianteId, DateOnly fecha, bool diaCerrado, CancellationToken ct = default)
    {
        logger.LogInformation("[ALERTAS simuladas] Aquí el Equipo 6 evaluaría el día {Fecha} del estudiante {EstudianteId}.", fecha, estudianteId);
        return Task.FromResult(0);
    }
}
