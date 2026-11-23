// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// NO forma parte del proyecto final: en el sistema integrado estas clases
// las entregan el Equipo 2 (Estudiante) y el Equipo 3 (CategoriaAlimento, TipoComida, Alimento).
// Tienen los mismos nombres y propiedades que usa el Equipo 4, por eso su código funciona sin cambios.

namespace SmartNutriTracker.Api.Data.Entities;

/// <summary>Versión reducida del estudiante (Equipo 2).</summary>
public class Estudiante
{
    public int Id { get; set; }
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public string Correo { get; set; } = string.Empty;
    public string Curso { get; set; } = string.Empty;
    public DateOnly FechaNacimiento { get; set; }
    public string Sexo { get; set; } = "F";
    public decimal PesoKg { get; set; }
    public decimal AlturaCm { get; set; }

    /// <summary>Factor de actividad física (1,2 sedentario … 1,9 muy activo).</summary>
    public decimal FactorActividad { get; set; } = 1.2m;

    /// <summary>Ajuste del objetivo en %: -15 bajar, 0 mantener, +10 ganar.</summary>
    public int AjusteObjetivo { get; set; }

    public bool Activo { get; set; } = true;

    public string NombreCompleto => $"{Nombres} {Apellidos}";
}

/// <summary>Igual que en el Equipo 3.</summary>
public class CategoriaAlimento
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
}

/// <summary>Igual que en el Equipo 3 (sin la relación con categorías sugeridas, que solo usa el Equipo 5).</summary>
public class TipoComida
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int Orden { get; set; }
    public decimal PorcentajeCalorias { get; set; }
}

/// <summary>Igual que en el Equipo 3. Los valores nutricionales son por porción.</summary>
public class Alimento
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int CategoriaAlimentoId { get; set; }
    public string PorcionDescripcion { get; set; } = string.Empty;
    public decimal PorcionGramos { get; set; }
    public decimal Calorias { get; set; }
    public decimal Proteinas { get; set; }
    public decimal Carbohidratos { get; set; }
    public decimal Grasas { get; set; }
    public decimal Fibra { get; set; }
    public decimal Azucares { get; set; }
    public decimal SodioMg { get; set; }
    public bool Activo { get; set; } = true;

    public CategoriaAlimento? CategoriaAlimento { get; set; }
}
