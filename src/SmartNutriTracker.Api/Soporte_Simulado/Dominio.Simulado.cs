// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// TotalesNutricionales es copia exacta del Equipo 5. ResultadoCalculo es una versión reducida.
namespace SmartNutriTracker.Api.Domain;

public sealed record TotalesNutricionales(decimal Calorias, decimal Proteinas, decimal Carbohidratos, decimal Grasas)
{
    public static readonly TotalesNutricionales Cero = new(0, 0, 0, 0);

    /// <summary>% de calorías por macronutriente (4 kcal/g proteína y carbohidrato, 9 kcal/g grasa).</summary>
    public (decimal Proteina, decimal Carbohidratos, decimal Grasas) DistribucionPorcentual()
    {
        var kcal = Proteinas * 4 + Carbohidratos * 4 + Grasas * 9;
        if (kcal <= 0) return (0, 0, 0);
        return (Math.Round(Proteinas * 4 / kcal * 100, 1),
                Math.Round(Carbohidratos * 4 / kcal * 100, 1),
                Math.Round(Grasas * 9 / kcal * 100, 1));
    }
}

/// <summary>Versión reducida del resultado del Equipo 5. El Equipo 4 solo usa CaloriasObjetivo.</summary>
public sealed record ResultadoCalculo(
    decimal Imc,
    string CategoriaImc,
    decimal Tmb,
    decimal FactorActividad,
    decimal GastoEnergeticoTotal,
    decimal CaloriasObjetivo);
