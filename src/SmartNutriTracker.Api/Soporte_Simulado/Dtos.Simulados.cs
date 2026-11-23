// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// ItemComidaDto, ComidaDto y ResumenNutricionalDto son copia exacta de los del Equipo 3 (los usa el Equipo 4).
// El resto son versiones reducidas de los DTOs del Equipo 1 (login) y de las listas que usa la pantalla.
using System.ComponentModel.DataAnnotations;

namespace SmartNutriTracker.Api.DTOs;

// ---------- Copia del Equipo 3 ----------
public sealed record ItemComidaDto(int Id, int AlimentoId, string Alimento, string Categoria, string Porcion, decimal Porciones,
    decimal Calorias, decimal Proteinas, decimal Carbohidratos, decimal Grasas);

public sealed record ComidaDto(int TipoComidaId, string TipoComida, int Orden, decimal Calorias, decimal Proteinas,
    decimal Carbohidratos, decimal Grasas, IReadOnlyList<ItemComidaDto> Items);

public sealed record ResumenNutricionalDto(decimal Calorias, decimal Proteinas, decimal Carbohidratos, decimal Grasas,
    decimal PctProteina, decimal PctCarbohidratos, decimal PctGrasas, string Evaluacion);

// ---------- Inicio de sesión de prueba (reemplaza al Equipo 1) ----------
public sealed class LoginRequest
{
    /// <example>carla.flores@innovare.edu.bo</example>
    [Required, EmailAddress, MaxLength(150)] public string Correo { get; set; } = string.Empty;

    /// <example>Innovare2026!</example>
    [Required, MaxLength(100)] public string Password { get; set; } = string.Empty;
}

public sealed record UsuarioActualDto(int Id, string Nombre, string Correo, string Rol, int? EstudianteId);

public sealed record LoginResponse(string Token, DateTime ExpiraEn, UsuarioActualDto Usuario);

// ---------- Listas que necesita la pantalla del Equipo 4 ----------
public sealed record OpcionDto(int Id, string Nombre, string? Codigo = null);

public sealed record CatalogosPruebaDto(IReadOnlyList<OpcionDto> TiposComida);

public sealed record EstudianteResumenDto(int Id, string NombreCompleto, string Curso);

public sealed record AlimentoResumenDto(int Id, string Nombre, string Categoria, string PorcionDescripcion,
    decimal Calorias, decimal Proteinas, decimal Carbohidratos, decimal Grasas);
