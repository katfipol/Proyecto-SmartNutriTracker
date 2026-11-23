// SOPORTE SIMULADO – solo para probar el bloque del Equipo 4.
// Endpoints mínimos que necesita la pantalla del Equipo 4:
//   /api/auth (Equipo 1), /api/catalogos (Equipo 1), /api/estudiantes (Equipo 2), /api/alimentos (Equipo 3).
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SmartNutriTracker.Api.Common;
using SmartNutriTracker.Api.Data;
using SmartNutriTracker.Api.DTOs;
using SmartNutriTracker.Api.Services;

namespace SmartNutriTracker.Api.Controllers;

/// <summary>SIMULADO – Inicio de sesión con cuentas de prueba (en el sistema real lo hace el Equipo 1).</summary>
[ApiController]
[Route("api/auth")]
[Produces("application/json")]
public class AuthPruebaController(SmartNutriDbContext db, IConfiguration config) : ControllerBase
{
    /// <summary>Inicia sesión. Contraseña de todas las cuentas: Innovare2026!</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        var correo = request.Correo.Trim().ToLowerInvariant();
        if (request.Password != UsuariosPrueba.Password)
            throw new NoAutorizadoException("Correo o contraseña incorrectos.");

        UsuarioActualDto? usuario = null;
        var personal = UsuariosPrueba.Personal.FirstOrDefault(p => p.Correo == correo);
        if (personal is not null)
        {
            usuario = new UsuarioActualDto(personal.Id, personal.Nombre, personal.Correo, personal.Rol, null);
        }
        else
        {
            var estudiante = await db.Estudiantes.AsNoTracking().FirstOrDefaultAsync(e => e.Correo == correo && e.Activo, ct);
            if (estudiante is not null)
                usuario = new UsuarioActualDto(UsuariosPrueba.OffsetEstudiantes + estudiante.Id,
                    estudiante.Nombres + " " + estudiante.Apellidos, estudiante.Correo, Roles.Estudiante, estudiante.Id);
        }

        if (usuario is null) throw new NoAutorizadoException("Correo o contraseña incorrectos.");

        var (token, expira) = GenerarToken(usuario);
        return Ok(new LoginResponse(token, expira, usuario));
    }

    /// <summary>Datos del usuario autenticado.</summary>
    [HttpGet("perfil")]
    [Authorize]
    public ActionResult<UsuarioActualDto> Perfil()
    {
        int? estudianteId = int.TryParse(User.FindFirstValue("estudianteId"), out var id) ? id : null;
        return Ok(new UsuarioActualDto(User.ObtenerUsuarioId(), User.FindFirstValue(ClaimTypes.Name) ?? string.Empty,
            User.FindFirstValue(ClaimTypes.Email) ?? string.Empty, User.ObtenerRol(), estudianteId));
    }

    /// <summary>Mismo formato de token JWT que el Equipo 1.</summary>
    private (string Token, DateTime Expira) GenerarToken(UsuarioActualDto usuario)
    {
        var jwt = config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt["Key"]!));
        var expira = DateTime.UtcNow.AddMinutes(jwt.GetValue("ExpiracionMinutos", 480));

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(ClaimTypes.Name, usuario.Nombre),
            new(ClaimTypes.Email, usuario.Correo),
            new(ClaimTypes.Role, usuario.Rol)
        };
        if (usuario.EstudianteId.HasValue) claims.Add(new Claim("estudianteId", usuario.EstudianteId.Value.ToString()));

        var token = new JwtSecurityToken(jwt["Issuer"], jwt["Audience"], claims, DateTime.UtcNow, expira,
            new SigningCredentials(key, SecurityAlgorithms.HmacSha256));
        return (new JwtSecurityTokenHandler().WriteToken(token), expira);
    }
}

/// <summary>SIMULADO – Catálogos que usa la pantalla (tiempos de comida).</summary>
[ApiController]
[Route("api/catalogos")]
[Authorize]
[Produces("application/json")]
public class CatalogosPruebaController(SmartNutriDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<CatalogosPruebaDto>> Obtener(CancellationToken ct)
    {
        var tipos = await db.TiposComida.AsNoTracking()
            .OrderBy(t => t.Orden)
            .Select(t => new OpcionDto(t.Id, t.Nombre, null))
            .ToListAsync(ct);
        return Ok(new CatalogosPruebaDto(tipos));
    }
}

/// <summary>SIMULADO – Lista de estudiantes para el selector del docente o nutricionista (Equipo 2).</summary>
[ApiController]
[Route("api/estudiantes")]
[Authorize(Roles = Roles.Personal)]
[Produces("application/json")]
public class EstudiantesPruebaController(IAccesoService acceso) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<EstudianteResumenDto>>> Listar(CancellationToken ct)
    {
        var lista = await acceso.EstudiantesVisibles().AsNoTracking()
            .OrderBy(e => e.Apellidos).ThenBy(e => e.Nombres)
            .Select(e => new EstudianteResumenDto(e.Id, e.Nombres + " " + e.Apellidos, e.Curso))
            .ToListAsync(ct);
        return Ok(lista);
    }
}

/// <summary>SIMULADO – Lista de alimentos activos para el formulario de consumo (Equipo 3).</summary>
[ApiController]
[Route("api/alimentos")]
[Authorize]
[Produces("application/json")]
public class AlimentosPruebaController(SmartNutriDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<AlimentoResumenDto>>> Listar(CancellationToken ct)
    {
        var lista = await db.Alimentos.AsNoTracking()
            .Where(a => a.Activo)
            .OrderBy(a => a.Nombre)
            .Select(a => new AlimentoResumenDto(a.Id, a.Nombre,
                a.CategoriaAlimento != null ? a.CategoriaAlimento.Nombre : string.Empty,
                a.PorcionDescripcion, a.Calorias, a.Proteinas, a.Carbohidratos, a.Grasas))
            .ToListAsync(ct);
        return Ok(lista);
    }
}
