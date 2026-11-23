namespace SmartNutriTracker.Api.Data.Entities;

public class RegistroConsumo
{
    public int Id { get; set; }
    public int EstudianteId { get; set; }
    public DateOnly Fecha { get; set; }
    public int TipoComidaId { get; set; }
    public int AlimentoId { get; set; }
    public decimal Porciones { get; set; }
    public DateTime FechaRegistro { get; set; } = DateTime.UtcNow;

    public TipoComida? TipoComida { get; set; }
    public Alimento? Alimento { get; set; }
}

public class RegistroHabito
{
    public int Id { get; set; }
    public int EstudianteId { get; set; }
    public DateOnly Fecha { get; set; }
    public decimal HorasSueno { get; set; }
    public int AguaMl { get; set; }
    public int MinutosActividad { get; set; }
    public string? Observaciones { get; set; }
}
