// BASE DEL SISTEMA (Equipo 1)
// SmartNutriTracker · Colegio Innovare
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Mvc;

namespace SmartNutriTracker.Api.Common;

/// <summary>HU-04 – Roles del sistema.</summary>
public static class Roles
{
    public const string Admin = "Admin";
    public const string Docente = "Docente";
    public const string Nutricionista = "Nutricionista";
    public const string Estudiante = "Estudiante";

    public const string Personal = Admin + "," + Docente + "," + Nutricionista;
    public const string Salud = Admin + "," + Nutricionista;
    public const string Todos = Admin + "," + Docente + "," + Nutricionista + "," + Estudiante;

    public static readonly IReadOnlyList<string> Lista = [Admin, Docente, Nutricionista, Estudiante];
}

public class NoEncontradoException(string mensaje) : Exception(mensaje);

public class ReglaNegocioException(string mensaje) : Exception(mensaje);

public class AccesoDenegadoException(string mensaje) : Exception(mensaje);

public class NoAutorizadoException(string mensaje) : Exception(mensaje);

public static class ClaimsPrincipalExtensions
{
    public static int ObtenerUsuarioId(this ClaimsPrincipal usuario)
    {
        var valor = usuario.FindFirstValue(ClaimTypes.NameIdentifier) ?? usuario.FindFirstValue("sub");
        return int.TryParse(valor, out var id) ? id : throw new NoAutorizadoException("Token sin identificador de usuario.");
    }

    public static string ObtenerRol(this ClaimsPrincipal usuario) =>
        usuario.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
}

/// <summary>HU-01 / HU-02 – Hash de contraseñas con PBKDF2-SHA256 (sin librerías externas).</summary>
public static class PasswordHasher
{
    private const int Iteraciones = 100_000;
    private const int TamanoSal = 16;
    private const int TamanoHash = 32;

    /// <summary>Formato: PBKDF2$iteraciones$salBase64$hashBase64</summary>
    public static string Hash(string password)
    {
        var sal = RandomNumberGenerator.GetBytes(TamanoSal);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, sal, Iteraciones, HashAlgorithmName.SHA256, TamanoHash);
        return $"PBKDF2${Iteraciones}${Convert.ToBase64String(sal)}${Convert.ToBase64String(hash)}";
    }

    public static bool Verificar(string password, string almacenado)
    {
        var partes = almacenado.Split('$');
        if (partes.Length != 4 || partes[0] != "PBKDF2" || !int.TryParse(partes[1], out var iteraciones)) return false;
        try
        {
            var sal = Convert.FromBase64String(partes[2]);
            var esperado = Convert.FromBase64String(partes[3]);
            var calculado = Rfc2898DeriveBytes.Pbkdf2(password, sal, iteraciones, HashAlgorithmName.SHA256, esperado.Length);
            return CryptographicOperations.FixedTimeEquals(calculado, esperado);
        }
        catch (FormatException)
        {
            return false;
        }
    }

    /// <summary>Política: mínimo 8 caracteres, una mayúscula, una minúscula y un número.</summary>
    public static void ValidarPolitica(string password)
    {
        if (string.IsNullOrEmpty(password) || password.Length < 8 ||
            !password.Any(char.IsUpper) || !password.Any(char.IsLower) || !password.Any(char.IsDigit))
        {
            throw new ReglaNegocioException("La contraseña debe tener al menos 8 caracteres, una mayúscula, una minúscula y un número.");
        }
    }
}

/// <summary>Cabeceras de seguridad básicas para la API y el frontend.</summary>
public class CabecerasSeguridadMiddleware(RequestDelegate next)
{
    public Task InvokeAsync(HttpContext context)
    {
        var h = context.Response.Headers;
        h["X-Content-Type-Options"] = "nosniff";
        h["X-Frame-Options"] = "DENY";
        h["Referrer-Policy"] = "no-referrer";
        h["X-XSS-Protection"] = "0";
        if (!context.Request.Path.StartsWithSegments("/swagger"))
        {
            h["Content-Security-Policy"] =
                "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; font-src 'self'; connect-src 'self'; frame-ancestors 'none'";
        }
        return next(context);
    }
}
