/* =====================================================================
   SmartNutriTracker - Colegio "Innovare"
   EQUIPO 2 - PERFIL Y REPORTES
   HU-08 a HU-12 · Cursos, estudiantes, niveles de actividad e historial de mediciones
   Motor: SQL Server 2019+ / SQL Server Express

   ORDEN DE EJECUCIÓN (base nueva): Equipo1 → Equipo2 → Equipo3 → Equipo4 → Equipo5 → Equipo6
   Requiere: Equipo 1.
   ===================================================================== */

IF DB_ID(N'SmartNutriTrackerDB') IS NULL
BEGIN
    RAISERROR(N'La base SmartNutriTrackerDB no existe. Ejecute primero el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

USE SmartNutriTrackerDB;
GO

IF OBJECT_ID(N'dbo.Usuarios', N'U') IS NULL
BEGIN
    RAISERROR(N'Falta el script del Equipo 1 (Usuarios).', 16, 1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID(N'dbo.Estudiantes', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'Las tablas del Equipo 2 ya existen. Para reinstalar, vuelva a ejecutar desde el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE TABLE dbo.NivelesActividad
(
    Id      INT IDENTITY(1,1) CONSTRAINT PK_NivelesActividad PRIMARY KEY,
    Codigo  NVARCHAR(20) NOT NULL CONSTRAINT UQ_NivelesActividad_Codigo UNIQUE,
    Nombre  NVARCHAR(60) NOT NULL,
    Factor  DECIMAL(4,3) NOT NULL CONSTRAINT CK_NivelesActividad_Factor CHECK (Factor BETWEEN 1 AND 2.5)
);

CREATE TABLE dbo.Cursos
(
    Id         INT IDENTITY(1,1) CONSTRAINT PK_Cursos PRIMARY KEY,
    Nombre     NVARCHAR(50) NOT NULL CONSTRAINT UQ_Cursos_Nombre UNIQUE,
    DocenteId  INT NULL CONSTRAINT FK_Cursos_Docente REFERENCES dbo.Usuarios(Id)
);

CREATE TABLE dbo.Estudiantes
(
    Id                INT IDENTITY(1,1) CONSTRAINT PK_Estudiantes PRIMARY KEY,
    UsuarioId         INT NULL CONSTRAINT FK_Estudiantes_Usuarios REFERENCES dbo.Usuarios(Id),
    Nombres           NVARCHAR(100) NOT NULL,
    Apellidos         NVARCHAR(100) NOT NULL,
    FechaNacimiento   DATE NOT NULL,
    Sexo              CHAR(1) NOT NULL CONSTRAINT CK_Estudiantes_Sexo CHECK (Sexo IN ('M','F')),
    CursoId           INT NOT NULL CONSTRAINT FK_Estudiantes_Cursos REFERENCES dbo.Cursos(Id),
    PesoKg            DECIMAL(5,2) NOT NULL CONSTRAINT CK_Estudiantes_Peso CHECK (PesoKg BETWEEN 10 AND 300),
    AlturaCm          DECIMAL(5,2) NOT NULL CONSTRAINT CK_Estudiantes_Altura CHECK (AlturaCm BETWEEN 80 AND 230),
    NivelActividadId  INT NOT NULL CONSTRAINT FK_Estudiantes_Nivel REFERENCES dbo.NivelesActividad(Id),
    -- FK a ObjetivosNutricionales (Equipo 5): la agrega el script del Equipo 5 (FK_Estudiantes_Objetivo).
    -- Valores: 1 = BAJAR, 2 = MANTENER, 3 = GANAR
    ObjetivoId        INT NOT NULL,
    Activo            BIT NOT NULL CONSTRAINT DF_Estudiantes_Activo DEFAULT (1),
    FechaRegistro     DATETIME2 NOT NULL CONSTRAINT DF_Estudiantes_Fecha DEFAULT (SYSUTCDATETIME())
);
CREATE UNIQUE INDEX UX_Estudiantes_Usuario ON dbo.Estudiantes (UsuarioId) WHERE UsuarioId IS NOT NULL;

-- Historial de peso y talla (progreso físico)
CREATE TABLE dbo.MedicionesEstudiante
(
    Id            INT IDENTITY(1,1) CONSTRAINT PK_MedicionesEstudiante PRIMARY KEY,
    EstudianteId  INT NOT NULL CONSTRAINT FK_Mediciones_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    Fecha         DATE NOT NULL,
    PesoKg        DECIMAL(5,2) NOT NULL,
    AlturaCm      DECIMAL(5,2) NOT NULL,
    CONSTRAINT UQ_Mediciones_EstudianteFecha UNIQUE (EstudianteId, Fecha)
);
GO

/* ---------- Datos semilla ---------- */
INSERT INTO dbo.Cursos (Nombre, DocenteId) VALUES
    (N'5to Secundaria A', (SELECT Id FROM dbo.Usuarios WHERE Correo = N'jvargas@innovare.edu.bo')),
    (N'6to Secundaria A', (SELECT Id FROM dbo.Usuarios WHERE Correo = N'ltorrez@innovare.edu.bo'));

INSERT INTO dbo.NivelesActividad (Codigo, Nombre, Factor) VALUES
    (N'SEDENTARIO', N'Sedentario (poco o nada de ejercicio)', 1.200),
    (N'LIGERO',     N'Ligero (1-3 días por semana)',          1.375),
    (N'MODERADO',   N'Moderado (3-5 días por semana)',        1.550),
    (N'ACTIVO',     N'Activo (6-7 días por semana)',          1.725),
    (N'MUY_ACTIVO', N'Muy activo (entrenamiento diario)',     1.900);

INSERT INTO dbo.Estudiantes (UsuarioId, Nombres, Apellidos, FechaNacimiento, Sexo, CursoId, PesoKg, AlturaCm, NivelActividadId, ObjetivoId)
SELECT u.Id, s.Nombres, s.Apellidos, s.FechaNacimiento, s.Sexo, c.Id, s.Peso, s.Altura, n.Id,
       CASE s.Objetivo WHEN N'BAJAR' THEN 1 WHEN N'MANTENER' THEN 2 ELSE 3 END  -- ids fijos del catálogo del Equipo 5
FROM (VALUES
    (1, N'ana.mamani@innovare.edu.bo',      N'Ana',   N'Mamani',    CAST('2010-05-10' AS DATE), 'F', N'5to Secundaria A', 45.0, 165.0, N'LIGERO',     N'MANTENER'),
    (2, N'luis.quispe@innovare.edu.bo',     N'Luis',  N'Quispe',    CAST('2009-08-22' AS DATE), 'M', N'6to Secundaria A', 65.0, 172.0, N'ACTIVO',     N'MANTENER'),
    (3, N'carla.flores@innovare.edu.bo',    N'Carla', N'Flores',    CAST('2011-02-14' AS DATE), 'F', N'5to Secundaria A', 70.0, 160.0, N'SEDENTARIO', N'BAJAR'),
    (4, N'diego.choque@innovare.edu.bo',    N'Diego', N'Choque',    CAST('2010-11-30' AS DATE), 'M', N'5to Secundaria A', 95.0, 170.0, N'MODERADO',   N'GANAR'),
    (5, N'sofia.gutierrez@innovare.edu.bo', N'Sofía', N'Gutiérrez', CAST('2009-03-03' AS DATE), 'F', N'6to Secundaria A', 55.0, 162.0, N'MODERADO',   N'MANTENER'),
    (6, N'mateo.condori@innovare.edu.bo',   N'Mateo', N'Condori',   CAST('2009-12-12' AS DATE), 'M', N'6to Secundaria A', 72.0, 178.0, N'MUY_ACTIVO', N'GANAR')
) AS s (Orden, Correo, Nombres, Apellidos, FechaNacimiento, Sexo, Curso, Peso, Altura, Nivel, Objetivo)
INNER JOIN dbo.Usuarios u ON u.Correo = s.Correo
INNER JOIN dbo.Cursos c ON c.Nombre = s.Curso
INNER JOIN dbo.NivelesActividad n ON n.Codigo = s.Nivel
ORDER BY s.Orden;

-- Historial de mediciones (hace 60 días, 30 días y hoy)
INSERT INTO dbo.MedicionesEstudiante (EstudianteId, Fecha, PesoKg, AlturaCm)
SELECT e.Id, DATEADD(DAY, -d.Dias, CAST(GETDATE() AS DATE)), e.PesoKg + d.Delta, e.AlturaCm
FROM dbo.Estudiantes e
CROSS JOIN (VALUES (60, 1.5), (30, 0.8), (0, 0.0)) AS d (Dias, Delta);
GO


/* Verificación */
SELECT 'NivelesActividad' AS Tabla, COUNT(*) AS Filas FROM dbo.NivelesActividad UNION ALL
SELECT 'Cursos' AS Tabla, COUNT(*) AS Filas FROM dbo.Cursos UNION ALL
SELECT 'Estudiantes' AS Tabla, COUNT(*) AS Filas FROM dbo.Estudiantes UNION ALL
SELECT 'MedicionesEstudiante' AS Tabla, COUNT(*) AS Filas FROM dbo.MedicionesEstudiante;
GO

SET NOEXEC OFF;
GO
