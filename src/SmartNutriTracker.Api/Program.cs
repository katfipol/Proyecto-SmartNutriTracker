using System.Reflection;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartNutriTracker.Api.Common;
using SmartNutriTracker.Api.Data;
using SmartNutriTracker.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<SmartNutriDbContext>(o =>
    o.UseSqlServer(builder.Configuration.GetConnectionString("SmartNutriDb")));

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IHabitosService, HabitosService>();
builder.Services.AddScoped<IAccesoService, AccesoServiceSimulado>();
builder.Services.AddScoped<IAuditoriaService, AuditoriaServiceSimulado>();
builder.Services.AddScoped<INutricionService, NutricionServiceSimulado>();
builder.Services.AddScoped<IAlertasService, AlertasServiceSimulado>();
var jwt = builder.Configuration.GetSection("Jwt");
var clave = jwt["Key"];
if (string.IsNullOrWhiteSpace(clave) || clave.Length < 32)
    throw new InvalidOperationException("Jwt:Key debe tener al menos 32 caracteres.");

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt["Issuer"],
            ValidateAudience = true,
            ValidAudience = jwt["Audience"],
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(clave)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            RoleClaimType = ClaimTypes.Role,
            NameClaimType = ClaimTypes.Name
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SmartNutriTracker API – Prueba Equipo 4",
        Version = "v1",
        Description = "Versión de prueba del bloque Registro de Hábitos (HU-19 a HU-22). " +
                      "Inicie sesión en POST /api/auth/login, copie el token y presione Authorize."
    });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Pegue solo el token JWT."
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } },
            Array.Empty<string>()
        }
    });
    var xml = Path.Combine(AppContext.BaseDirectory, $"{Assembly.GetExecutingAssembly().GetName().Name}.xml");
    if (File.Exists(xml)) c.IncludeXmlComments(xml);
});

var app = builder.Build();

app.UseMiddleware<ManejoErroresMiddleware>();
app.UseMiddleware<CabecerasSeguridadMiddleware>();

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartNutriTracker – Prueba Equipo 4");
    c.DocumentTitle = "SmartNutriTracker – Prueba Equipo 4";
});
app.UseDefaultFiles();
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/api/salud", async (SmartNutriDbContext db) =>
{
    var bd = await db.Database.CanConnectAsync();
    return Results.Ok(new { estado = bd ? "ok" : "sin conexión a la base de datos", baseDeDatos = bd, fecha = DateTime.Now });
}).AllowAnonymous();

app.Logger.LogInformation("Versión de prueba del Equipo 4 iniciada. Frontend: / · Swagger: /swagger");
app.Run();
