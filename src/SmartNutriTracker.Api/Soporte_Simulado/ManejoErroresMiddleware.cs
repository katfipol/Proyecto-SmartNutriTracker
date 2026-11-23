// SOPORTE PARA LA VERSIÓN DE PRUEBA: copia sin cambios del middleware del Equipo 6.
// EQUIPO 6 – Notificaciones y Testing
// SmartNutriTracker · Colegio Innovare
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.AspNetCore.Mvc;

namespace SmartNutriTracker.Api.Common;

/// <summary>Convierte excepciones en respuestas ProblemDetails y las registra en el log (HU-29).</summary>
public class ManejoErroresMiddleware(RequestDelegate next, ILogger<ManejoErroresMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            var (status, titulo) = ex switch
            {
                NoEncontradoException => (StatusCodes.Status404NotFound, "Recurso no encontrado"),
                ReglaNegocioException or ArgumentException => (StatusCodes.Status400BadRequest, "Solicitud inválida"),
                AccesoDenegadoException => (StatusCodes.Status403Forbidden, "Acceso denegado"),
                NoAutorizadoException => (StatusCodes.Status401Unauthorized, "No autorizado"),
                InvalidOperationException => (StatusCodes.Status422UnprocessableEntity, "No se pudo procesar"),
                _ => (StatusCodes.Status500InternalServerError, "Error interno del servidor")
            };

            if (status == StatusCodes.Status500InternalServerError)
                logger.LogError(ex, "Error no controlado en {Metodo} {Ruta}", context.Request.Method, context.Request.Path);
            else
                logger.LogWarning("{Titulo}: {Mensaje} ({Metodo} {Ruta})", titulo, ex.Message, context.Request.Method, context.Request.Path);

            if (context.Response.HasStarted) throw;

            context.Response.Clear();
            context.Response.StatusCode = status;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = status,
                Title = titulo,
                Detail = status == StatusCodes.Status500InternalServerError ? "Ocurrió un error inesperado. Revise los logs." : ex.Message,
                Instance = context.Request.Path
            }, options: null, contentType: "application/problem+json");
        }
    }
}
