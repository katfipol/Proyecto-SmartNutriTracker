using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SmartNutriTracker.Api.Common;
using SmartNutriTracker.Api.DTOs;
using SmartNutriTracker.Api.Data.Entities;
using SmartNutriTracker.Api.Data;
using SmartNutriTracker.Api.Domain;

namespace SmartNutriTracker.Api.Services;

public static partial class Mapeos
{
    public static HabitoDto ADto(RegistroHabito h) =>
        new(h.Id, h.EstudianteId, h.Fecha, h.HorasSueno, h.AguaMl, h.MinutosActividad, h.Observaciones);
}
