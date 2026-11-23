// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// Copia exacta de las funciones del Equipo 3 (Mapeos.Equipo3.cs) que usa HabitosService.
using SmartNutriTracker.Api.DTOs;
using SmartNutriTracker.Api.Data.Entities;
using SmartNutriTracker.Api.Domain;

namespace SmartNutriTracker.Api.Services;

public static partial class Mapeos
{
    /// <summary>HU-17 – Totales y evaluación de un conjunto de alimentos (rangos AMDR de macronutrientes).</summary>
    public static ResumenNutricionalDto Resumen(TotalesNutricionales t)
    {
        var (p, c, g) = t.DistribucionPorcentual();
        var problemas = new List<string>();
        if (t.Calorias > 0)
        {
            if (p < 10) problemas.Add("proteína baja"); else if (p > 35) problemas.Add("proteína alta");
            if (c < 45) problemas.Add("carbohidratos bajos"); else if (c > 65) problemas.Add("carbohidratos altos");
            if (g < 20) problemas.Add("grasas bajas"); else if (g > 35) problemas.Add("grasas altas");
        }
        var evaluacion = t.Calorias <= 0 ? "Sin datos"
            : problemas.Count == 0 ? "Saludable: distribución de macronutrientes balanceada"
            : "Revisar: " + string.Join(", ", problemas);
        return new ResumenNutricionalDto(t.Calorias, t.Proteinas, t.Carbohidratos, t.Grasas, p, c, g, evaluacion);
    }

    /// <summary>Agrupa ítems (id, tipo de comida, alimento, porciones) por tiempo de comida.</summary>
    public static IReadOnlyList<ComidaDto> AgruparComidas(IEnumerable<(int Id, TipoComida Tipo, Alimento Alimento, decimal Porciones)> items) =>
        items.GroupBy(i => i.Tipo.Id)
            .Select(g =>
            {
                var tipo = g.First().Tipo;
                var lista = g.Select(i => new ItemComidaDto(i.Id, i.Alimento.Id, i.Alimento.Nombre, i.Alimento.CategoriaAlimento?.Nombre ?? string.Empty,
                    i.Alimento.PorcionDescripcion, i.Porciones,
                    Math.Round(i.Alimento.Calorias * i.Porciones, 1), Math.Round(i.Alimento.Proteinas * i.Porciones, 1),
                    Math.Round(i.Alimento.Carbohidratos * i.Porciones, 1), Math.Round(i.Alimento.Grasas * i.Porciones, 1))).ToList();
                return new ComidaDto(tipo.Id, tipo.Nombre, tipo.Orden, lista.Sum(x => x.Calorias), lista.Sum(x => x.Proteinas),
                    lista.Sum(x => x.Carbohidratos), lista.Sum(x => x.Grasas), lista);
            })
            .OrderBy(c => c.Orden)
            .ToList();

    public static TotalesNutricionales Totales(IEnumerable<(Alimento Alimento, decimal Porciones)> items)
    {
        decimal k = 0, p = 0, c = 0, g = 0;
        foreach (var (a, por) in items) { k += a.Calorias * por; p += a.Proteinas * por; c += a.Carbohidratos * por; g += a.Grasas * por; }
        return new TotalesNutricionales(Math.Round(k, 1), Math.Round(p, 1), Math.Round(c, 1), Math.Round(g, 1));
    }
}
