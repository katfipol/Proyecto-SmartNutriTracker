using System.ComponentModel.DataAnnotations;

namespace SmartNutriTracker.Api.DTOs;

public sealed class ConsumoRequest
{
    [Required, Range(1, int.MaxValue)] public int EstudianteId { get; set; }
    [Required] public DateOnly Fecha { get; set; }
    [Required, Range(1, int.MaxValue)] public int TipoComidaId { get; set; }
    [Required, Range(1, int.MaxValue)] public int AlimentoId { get; set; }
    [Required, Range(0.25, 10)] public decimal Porciones { get; set; }
}

public sealed class ActualizarConsumoRequest
{
    [Required, Range(1, int.MaxValue)] public int TipoComidaId { get; set; }
    [Required, Range(1, int.MaxValue)] public int AlimentoId { get; set; }
    [Required, Range(0.25, 10)] public decimal Porciones { get; set; }
}

public sealed record DiaConsumoDto(int EstudianteId, DateOnly Fecha, decimal CaloriasObjetivo, IReadOnlyList<ComidaDto> Comidas,
    ResumenNutricionalDto Totales, decimal Azucares, decimal SodioMg, HabitoDto? Habitos);

public sealed class HabitoRequest
{
    [Required, Range(1, int.MaxValue)] public int EstudianteId { get; set; }
    [Required] public DateOnly Fecha { get; set; }
    [Required, Range(0, 24)] public decimal HorasSueno { get; set; }
    [Required, Range(0, 10000)] public int AguaMl { get; set; }
    [Required, Range(0, 1440)] public int MinutosActividad { get; set; }
    [MaxLength(300)] public string? Observaciones { get; set; }
}

public sealed record HabitoDto(int Id, int EstudianteId, DateOnly Fecha, decimal HorasSueno, int AguaMl, int MinutosActividad, string? Observaciones);

public sealed record HistorialDiaDto(DateOnly Fecha, decimal Calorias, decimal Proteinas, decimal Carbohidratos, decimal Grasas,
    int RegistrosConsumo, HabitoDto? Habitos);
