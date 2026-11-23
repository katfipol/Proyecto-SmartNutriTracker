# SmartNutriTracker · Versión de prueba del Equipo 4 – Registro de Hábitos

**Tecnologías:** .NET 10 · ASP.NET Core Web API · Entity Framework Core 10 · SQL Server · JWT · Swagger · HTML + JavaScript + Bootstrap 5

---

## 1. Cómo ejecutar

### 1.1 Base de datos (SSMS)
1. Conéctese a su servidor, por ejemplo `DESKTOP-9BSSU1F`, con Autenticación de Windows.
2. Ejecute **en este orden**, cada uno con F5:
   1. `database/0_Soporte_Prueba_Equipo4.sql`
   2. `database/por_equipo/4_Equipo4_Habitos.sql`


### 1.2 Cadena de conexión
En `src/SmartNutriTracker.Api/appsettings.json`, cambie `Server=DESKTOP-9BSSU1F` por el nombre de su servidor si es otro. En JSON, la barra va doble: `Server=PC\\SQLEXPRESS`.

### 1.3 Visual Studio 2026
1. Abra `SmartNutriTracker.slnx`.
2. Elija el perfil **http** junto al botón ▶.
3. Pulse F5. Se abrirán:
   - Frontend: http://localhost:5200
   - Swagger: http://localhost:5200/swagger
   - Salud de la API y la base de datos: http://localhost:5200/api/salud

---

## 2. Cuentas de prueba (contraseña `Innovare2026!`)

| Rol | Correo | Qué ve |
|---|---|---|
| Estudiante | carla.flores@innovare.edu.bo | Su propio registro diario |
| Estudiante | luis.quispe@innovare.edu.bo | Su propio registro diario |
| Docente | jvargas@innovare.edu.bo | Estudiantes de 5to Secundaria A |
| Nutricionista | nutricion@innovare.edu.bo | Todos los estudiantes |

---

## 3. Qué probar

| HU | Prueba | Resultado esperado |
|---|---|---|
| HU-19 | **Agregar alimento** en la fecha de hoy | Aparece en su tiempo de comida y suben los totales |
| HU-20 | Guardar sueño, agua y actividad | Se guarda y el botón cambia a **Actualizar hábitos** |
| HU-21 | Tabla **Historial (últimos 30 días)** → **Ver** | Muestra la semana de datos de prueba y salta al día elegido |
| HU-22 | Editar o eliminar un alimento; actualizar o eliminar hábitos | Se corrige el mismo registro |
| Reglas | Ir a un día de hace más de 7 días | Aparece como **solo lectura** |
| Seguridad | Docente: el selector muestra solo estudiantes de 5to A | Control de acceso por rol |



```