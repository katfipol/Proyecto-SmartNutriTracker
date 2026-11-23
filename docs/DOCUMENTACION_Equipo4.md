# SmartNutriTracker · Equipo 4 – Registro de Hábitos

**Historias de usuario:** HU-19 a HU-22  
**Proyecto:** SmartNutriTracker - Colegio "Innovare" - Programación Web III  
**Tecnologías:** .NET 10 - ASP.NET Core Web API - Entity Framework Core 10 - SQL Server - HTML + JS + Bootstrap 5

---

## 1. Historias de usuario implementadas

| HU | Descripción | Implementación |
|---|---|---|
| HU-19 | Registrar consumo real de alimentos | `HabitosService.AgregarConsumoAsync` · `POST /api/consumos` |
| HU-20 | Registrar hábitos diarios | `HabitosService.GuardarHabitosAsync` · `PUT /api/habitos` (crea o actualiza el día) |
| HU-21 | Ver historial de hábitos | `GET /api/habitos/estudiante/{id}/historial` (hasta 3 meses) |
| HU-22 | Actualizar registro diario | `PUT/DELETE /api/consumos/{id}`, `DELETE /api/habitos/{id}` |

### Reglas de negocio
- No se registran fechas futuras.
- Solo se pueden corregir los últimos 7 días.
- Hay un registro de hábitos por estudiante y día (`UNIQUE`).
- Cada registro dispara la evaluación de alertas del Equipo 6.

## 2. Base de datos

**Script:** `database/por_equipo/4_Equipo4_Habitos.sql`

### Tablas del equipo
- `RegistrosConsumo`
- `RegistrosHabitos`

### Normalización (3FN)
- `RegistrosConsumo` guarda solo `AlimentoId`, `TipoComidaId` y `Porciones`. Los totales del día se calculan, y la vista `vw_ConsumoDiario` los agrupa.
- `RegistrosHabitos` tiene una fila por (estudiante, día). Todos sus campos dependen de esa clave.

## 3. API REST (endpoints del equipo)

| Método | Ruta | Roles | Descripción |
|---|---|---|---|
| GET | `/api/consumos/estudiante/{estudianteId}` | Cualquier usuario autenticado | Comidas, totales y hábitos de un día (fecha yyyy-MM-dd, por defecto hoy). |
| POST | `/api/consumos` | Cualquier usuario autenticado | Registrar alimento consumido |
| PUT | `/api/consumos/{id}` | Cualquier usuario autenticado | Actualizar |
| DELETE | `/api/consumos/{id}` | Cualquier usuario autenticado | Eliminar |
| PUT | `/api/habitos` | Cualquier usuario autenticado | Registra o actualiza los hábitos del día (sueño, agua, actividad). |
| DELETE | `/api/habitos/{id}` | Cualquier usuario autenticado | Eliminar |
| GET | `/api/habitos/estudiante/{estudianteId}/historial` | Cualquier usuario autenticado | HU-21 – Historial (por defecto, últimos 30 días). |

Todas las rutas (salvo el login) requieren el encabezado `Authorization: Bearer <token>`.
Para probarlas en Swagger (`/swagger`):
1. Inicie sesión en `POST /api/auth/login`.
2. Copie el token.
3. Presione **Authorize**.

## 5. Archivos del equipo

**Backend**
- `src/SmartNutriTracker.Api/Modulos/Equipo4_Habitos/ContextoDatos.cs`
- `src/SmartNutriTracker.Api/Modulos/Equipo4_Habitos/Controladores.cs`
- `src/SmartNutriTracker.Api/Modulos/Equipo4_Habitos/Dtos.cs`
- `src/SmartNutriTracker.Api/Modulos/Equipo4_Habitos/Entidades.cs`
- `src/SmartNutriTracker.Api/Modulos/Equipo4_Habitos/Servicios/HabitosService.cs`
- `src/SmartNutriTracker.Api/Modulos/Equipo4_Habitos/Servicios/Mapeos.Equipo4.cs`

**Frontend**
- `src/SmartNutriTracker.Api/wwwroot/js/vistas/registro.js`

**Base de datos**
- `database/por_equipo/4_Equipo4_Habitos.sql`

