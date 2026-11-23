using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartNutriTracker.Api.Common;
using SmartNutriTracker.Api.DTOs;
using SmartNutriTracker.Api.Services;

namespace SmartNutriTracker.Api.Controllers;

[ApiController]
[Route("api/consumos")]
[Authorize]
[Produces("application/json")]
public class ConsumosController(IHabitosService servicio) : ControllerBase
{
    [HttpGet("estudiante/{estudianteId:int}")]
    public async Task<ActionResult<DiaConsumoDto>> Dia(int estudianteId, [FromQuery] DateOnly? fecha, CancellationToken ct) =>
        Ok(await servicio.DiaAsync(estudianteId, fecha ?? DateOnly.FromDateTime(DateTime.Today), ct));

    [HttpPost]
    public async Task<ActionResult<ItemComidaDto>> Agregar([FromBody] ConsumoRequest request, CancellationToken ct) =>
        StatusCode(StatusCodes.Status201Created, await servicio.AgregarConsumoAsync(request, ct));

    [HttpPut("{id:int}")]
    public async Task<ActionResult<ItemComidaDto>> Actualizar(int id, [FromBody] ActualizarConsumoRequest request, CancellationToken ct) =>
        Ok(await servicio.ActualizarConsumoAsync(id, request, ct));

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        await servicio.EliminarConsumoAsync(id, ct);
        return NoContent();
    }
}

/// <summary>EQUIPO 4 – HU-20 / HU-21 / HU-22: hábitos diarios e historial.</summary>
[ApiController]
[Route("api/habitos")]
[Authorize]
[Produces("application/json")]
public class HabitosController(IHabitosService servicio) : ControllerBase
{
    /// <summary>Registra o actualiza los hábitos del día (sueño, agua, actividad).</summary>
    [HttpPut]
    public async Task<ActionResult<HabitoDto>> Guardar([FromBody] HabitoRequest request, CancellationToken ct) =>
        Ok(await servicio.GuardarHabitosAsync(request, ct));

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        await servicio.EliminarHabitosAsync(id, ct);
        return NoContent();
    }

    /// <summary>HU-21 – Historial (por defecto, últimos 30 días).</summary>
    [HttpGet("estudiante/{estudianteId:int}/historial")]
    public async Task<ActionResult<IReadOnlyList<HistorialDiaDto>>> Historial(int estudianteId, [FromQuery] DateOnly? desde, [FromQuery] DateOnly? hasta, CancellationToken ct)
    {
        var fin = hasta ?? DateOnly.FromDateTime(DateTime.Today);
        return Ok(await servicio.HistorialAsync(estudianteId, desde ?? fin.AddDays(-29), fin, ct));
    }
}
