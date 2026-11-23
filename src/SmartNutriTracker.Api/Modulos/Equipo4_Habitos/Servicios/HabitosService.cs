using Microsoft.EntityFrameworkCore;
using SmartNutriTracker.Api.Common;
using SmartNutriTracker.Api.DTOs;
using SmartNutriTracker.Api.Data.Entities;
using SmartNutriTracker.Api.Data;
using SmartNutriTracker.Api.Domain;

namespace SmartNutriTracker.Api.Services;

public interface IHabitosService
{
    Task<DiaConsumoDto> DiaAsync(int estudianteId, DateOnly fecha, CancellationToken ct = default);
    Task<ItemComidaDto> AgregarConsumoAsync(ConsumoRequest request, CancellationToken ct = default);
    Task<ItemComidaDto> ActualizarConsumoAsync(int id, ActualizarConsumoRequest request, CancellationToken ct = default);
    Task EliminarConsumoAsync(int id, CancellationToken ct = default);
    Task<HabitoDto> GuardarHabitosAsync(HabitoRequest request, CancellationToken ct = default);
    Task EliminarHabitosAsync(int id, CancellationToken ct = default);
    Task<IReadOnlyList<HistorialDiaDto>> HistorialAsync(int estudianteId, DateOnly desde, DateOnly hasta, CancellationToken ct = default);
}

public class HabitosService(
    SmartNutriDbContext db,
    IAccesoService acceso,
    INutricionService nutricion,
    IAlertasService alertas,
    IAuditoriaService auditoria) : IHabitosService
{
    private const int DiasEditables = 7;

    public async Task<DiaConsumoDto> DiaAsync(int estudianteId, DateOnly fecha, CancellationToken ct = default)
    {
        await acceso.VerificarEstudianteAsync(estudianteId, ct);
        var registros = await db.RegistrosConsumo.AsNoTracking()
            .Where(r => r.EstudianteId == estudianteId && r.Fecha == fecha)
            .Include(r => r.TipoComida)
            .Include(r => r.Alimento).ThenInclude(a => a!.CategoriaAlimento)
            .OrderBy(r => r.Id)
            .ToListAsync(ct);

        var e = await nutricion.CargarEstudianteAsync(estudianteId, ct);
        var calculo = await nutricion.CalcularEstudianteAsync(e, fecha, ct: ct);
        var habito = await db.RegistrosHabitos.AsNoTracking().FirstOrDefaultAsync(h => h.EstudianteId == estudianteId && h.Fecha == fecha, ct);

        var comidas = Mapeos.AgruparComidas(registros.Select(r => (r.Id, r.TipoComida!, r.Alimento!, r.Porciones)));
        var totales = Mapeos.Resumen(Mapeos.Totales(registros.Select(r => (r.Alimento!, r.Porciones))));
        return new DiaConsumoDto(estudianteId, fecha, calculo.CaloriasObjetivo, comidas, totales,
            Math.Round(registros.Sum(r => r.Alimento!.Azucares * r.Porciones), 1),
            Math.Round(registros.Sum(r => r.Alimento!.SodioMg * r.Porciones), 0),
            habito is null ? null : Mapeos.ADto(habito));
    }

    public async Task<ItemComidaDto> AgregarConsumoAsync(ConsumoRequest r, CancellationToken ct = default)
    {
        await acceso.VerificarEstudianteAsync(r.EstudianteId, ct);
        ValidarFecha(r.Fecha);
        var alimento = await ValidarAlimentoYTipoAsync(r.AlimentoId, r.TipoComidaId, ct);

        var registro = new RegistroConsumo
        {
            EstudianteId = r.EstudianteId, Fecha = r.Fecha, TipoComidaId = r.TipoComidaId,
            AlimentoId = r.AlimentoId, Porciones = r.Porciones, FechaRegistro = DateTime.UtcNow
        };
        db.RegistrosConsumo.Add(registro);
        await db.SaveChangesAsync(ct);
        await auditoria.RegistrarAsync("REGISTRAR_CONSUMO", "RegistroConsumo", registro.Id,
            $"Estudiante {r.EstudianteId}: {alimento.Nombre} x{r.Porciones} ({r.Fecha})", ct: ct);
        await alertas.EvaluarDiaAsync(r.EstudianteId, r.Fecha, diaCerrado: false, ct);
        return ADto(registro.Id, alimento, r.Porciones);
    }

    public async Task<ItemComidaDto> ActualizarConsumoAsync(int id, ActualizarConsumoRequest r, CancellationToken ct = default)
    {
        var registro = await db.RegistrosConsumo.FirstOrDefaultAsync(x => x.Id == id, ct) ?? throw new NoEncontradoException($"Registro {id} no encontrado.");
        await acceso.VerificarEstudianteAsync(registro.EstudianteId, ct);
        ValidarFecha(registro.Fecha);
        var alimento = await ValidarAlimentoYTipoAsync(r.AlimentoId, r.TipoComidaId, ct);

        registro.TipoComidaId = r.TipoComidaId;
        registro.AlimentoId = r.AlimentoId;
        registro.Porciones = r.Porciones;
        await db.SaveChangesAsync(ct);
        await auditoria.RegistrarAsync("ACTUALIZAR_CONSUMO", "RegistroConsumo", id, $"{alimento.Nombre} x{r.Porciones}", ct: ct);
        await alertas.EvaluarDiaAsync(registro.EstudianteId, registro.Fecha, diaCerrado: false, ct);
        return ADto(id, alimento, r.Porciones);
    }

    public async Task EliminarConsumoAsync(int id, CancellationToken ct = default)
    {
        var registro = await db.RegistrosConsumo.FirstOrDefaultAsync(x => x.Id == id, ct) ?? throw new NoEncontradoException($"Registro {id} no encontrado.");
        await acceso.VerificarEstudianteAsync(registro.EstudianteId, ct);
        ValidarFecha(registro.Fecha);
        db.RegistrosConsumo.Remove(registro);
        await db.SaveChangesAsync(ct);
        await auditoria.RegistrarAsync("ELIMINAR_CONSUMO", "RegistroConsumo", id, $"Estudiante {registro.EstudianteId} ({registro.Fecha})", ct: ct);
    }

    public async Task<HabitoDto> GuardarHabitosAsync(HabitoRequest r, CancellationToken ct = default)
    {
        await acceso.VerificarEstudianteAsync(r.EstudianteId, ct);
        ValidarFecha(r.Fecha);

        var h = await db.RegistrosHabitos.FirstOrDefaultAsync(x => x.EstudianteId == r.EstudianteId && x.Fecha == r.Fecha, ct);
        var nuevo = h is null;
        h ??= new RegistroHabito { EstudianteId = r.EstudianteId, Fecha = r.Fecha };
        h.HorasSueno = r.HorasSueno;
        h.AguaMl = r.AguaMl;
        h.MinutosActividad = r.MinutosActividad;
        h.Observaciones = string.IsNullOrWhiteSpace(r.Observaciones) ? null : r.Observaciones.Trim();
        if (nuevo) db.RegistrosHabitos.Add(h);
        await db.SaveChangesAsync(ct);

        await auditoria.RegistrarAsync(nuevo ? "REGISTRAR_HABITOS" : "ACTUALIZAR_HABITOS", "RegistroHabito", h.Id,
            $"Estudiante {r.EstudianteId} ({r.Fecha}): sueño {r.HorasSueno} h, agua {r.AguaMl} ml, actividad {r.MinutosActividad} min", ct: ct);
        await alertas.EvaluarDiaAsync(r.EstudianteId, r.Fecha, diaCerrado: false, ct);
        return Mapeos.ADto(h);
    }

    public async Task EliminarHabitosAsync(int id, CancellationToken ct = default)
    {
        var h = await db.RegistrosHabitos.FirstOrDefaultAsync(x => x.Id == id, ct) ?? throw new NoEncontradoException($"Registro {id} no encontrado.");
        await acceso.VerificarEstudianteAsync(h.EstudianteId, ct);
        ValidarFecha(h.Fecha);
        db.RegistrosHabitos.Remove(h);
        await db.SaveChangesAsync(ct);
        await auditoria.RegistrarAsync("ELIMINAR_HABITOS", "RegistroHabito", id, $"Estudiante {h.EstudianteId} ({h.Fecha})", ct: ct);
    }

    public async Task<IReadOnlyList<HistorialDiaDto>> HistorialAsync(int estudianteId, DateOnly desde, DateOnly hasta, CancellationToken ct = default)
    {
        await acceso.VerificarEstudianteAsync(estudianteId, ct);
        if (desde > hasta) throw new ReglaNegocioException("La fecha 'desde' no puede ser mayor que 'hasta'.");
        if (hasta.DayNumber - desde.DayNumber > 92) throw new ReglaNegocioException("El rango máximo es de 3 meses.");

        var consumo = await db.RegistrosConsumo.AsNoTracking()
            .Where(r => r.EstudianteId == estudianteId && r.Fecha >= desde && r.Fecha <= hasta)
            .Select(r => new
            {
                r.Fecha,
                Kcal = r.Alimento!.Calorias * r.Porciones,
                Prot = r.Alimento.Proteinas * r.Porciones,
                Carb = r.Alimento.Carbohidratos * r.Porciones,
                Gras = r.Alimento.Grasas * r.Porciones
            })
            .GroupBy(x => x.Fecha)
            .Select(g => new
            {
                Fecha = g.Key,
                Calorias = g.Sum(x => x.Kcal),
                Proteinas = g.Sum(x => x.Prot),
                Carbohidratos = g.Sum(x => x.Carb),
                Grasas = g.Sum(x => x.Gras),
                Registros = g.Count()
            })
            .ToListAsync(ct);
        var habitos = await db.RegistrosHabitos.AsNoTracking()
            .Where(h => h.EstudianteId == estudianteId && h.Fecha >= desde && h.Fecha <= hasta)
            .ToListAsync(ct);

        var fechas = consumo.Select(c => c.Fecha).Union(habitos.Select(h => h.Fecha)).OrderByDescending(f => f);
        return fechas.Select(f =>
        {
            var c = consumo.FirstOrDefault(x => x.Fecha == f);
            var h = habitos.FirstOrDefault(x => x.Fecha == f);
            return new HistorialDiaDto(f, Math.Round(c?.Calorias ?? 0, 0), Math.Round(c?.Proteinas ?? 0, 1),
                Math.Round(c?.Carbohidratos ?? 0, 1), Math.Round(c?.Grasas ?? 0, 1), c?.Registros ?? 0,
                h is null ? null : Mapeos.ADto(h));
        }).ToList();
    }

    private static void ValidarFecha(DateOnly fecha)
    {
        var hoy = DateOnly.FromDateTime(DateTime.Today);
        if (fecha > hoy) throw new ReglaNegocioException("No se pueden registrar datos de fechas futuras.");
        if (fecha < hoy.AddDays(-DiasEditables))
            throw new ReglaNegocioException($"Solo se pueden registrar o corregir datos de los últimos {DiasEditables} días.");
    }

    private async Task<Alimento> ValidarAlimentoYTipoAsync(int alimentoId, int tipoComidaId, CancellationToken ct)
    {
        if (!await db.TiposComida.AnyAsync(t => t.Id == tipoComidaId, ct)) throw new ReglaNegocioException("Tiempo de comida no válido.");
        return await db.Alimentos.AsNoTracking().Include(a => a.CategoriaAlimento)
                   .FirstOrDefaultAsync(a => a.Id == alimentoId && a.Activo, ct)
               ?? throw new ReglaNegocioException("Alimento inexistente o inactivo.");
    }

    private static ItemComidaDto ADto(int id, Alimento a, decimal porciones) =>
        new(id, a.Id, a.Nombre, a.CategoriaAlimento?.Nombre ?? string.Empty, a.PorcionDescripcion, porciones,
            Math.Round(a.Calorias * porciones, 1), Math.Round(a.Proteinas * porciones, 1),
            Math.Round(a.Carbohidratos * porciones, 1), Math.Round(a.Grasas * porciones, 1));
}
