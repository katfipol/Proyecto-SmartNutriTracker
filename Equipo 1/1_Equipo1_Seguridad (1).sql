/* =====================================================================
   SmartNutriTracker - Colegio "Innovare"
   EQUIPO 1 - AUTENTICACIÓN Y SEGURIDAD
   HU-01 a HU-05 · Crea la base de datos, usuarios, roles y auditoría
   Motor: SQL Server 2019+ / SQL Server Express

   ORDEN DE EJECUCIÓN (base nueva): Equipo1 → Equipo2 → Equipo3 → Equipo4 → Equipo5 → Equipo6
   ATENCIÓN: este script ELIMINA y vuelve a crear la base SmartNutriTrackerDB.
   Contraseña de todos los usuarios de prueba: Innovare2026!
   ===================================================================== */

USE master;
GO

IF DB_ID(N'SmartNutriTrackerDB') IS NOT NULL
BEGIN
    ALTER DATABASE SmartNutriTrackerDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SmartNutriTrackerDB;
END
GO

CREATE DATABASE SmartNutriTrackerDB;
GO

USE SmartNutriTrackerDB;
GO

CREATE TABLE dbo.Roles
(
    Id      INT IDENTITY(1,1) CONSTRAINT PK_Roles PRIMARY KEY,
    Nombre  NVARCHAR(30) NOT NULL CONSTRAINT UQ_Roles_Nombre UNIQUE
);

CREATE TABLE dbo.Usuarios
(
    Id                INT IDENTITY(1,1) CONSTRAINT PK_Usuarios PRIMARY KEY,
    Nombre            NVARCHAR(100) NOT NULL,
    Correo            NVARCHAR(150) NOT NULL CONSTRAINT UQ_Usuarios_Correo UNIQUE,
    PasswordHash      NVARCHAR(300) NOT NULL,
    RolId             INT NOT NULL CONSTRAINT FK_Usuarios_Roles REFERENCES dbo.Roles(Id),
    Activo            BIT NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
    IntentosFallidos  INT NOT NULL CONSTRAINT DF_Usuarios_Intentos DEFAULT (0),
    BloqueadoHasta    DATETIME2 NULL,
    UltimoAcceso      DATETIME2 NULL,
    FechaCreacion     DATETIME2 NOT NULL CONSTRAINT DF_Usuarios_Fecha DEFAULT (SYSUTCDATETIME())
);

CREATE TABLE dbo.LogsAuditoria
(
    Id           BIGINT IDENTITY(1,1) CONSTRAINT PK_LogsAuditoria PRIMARY KEY,
    UsuarioId    INT NULL CONSTRAINT FK_LogsAuditoria_Usuarios REFERENCES dbo.Usuarios(Id),
    Accion       NVARCHAR(50)   NOT NULL,
    Entidad      NVARCHAR(50)   NOT NULL,
    EntidadId    NVARCHAR(50)   NULL,
    Detalle      NVARCHAR(1000) NULL,
    DireccionIp  NVARCHAR(45)   NULL,
    Fecha        DATETIME2 NOT NULL CONSTRAINT DF_LogsAuditoria_Fecha DEFAULT (SYSUTCDATETIME())
);
CREATE INDEX IX_LogsAuditoria_Fecha ON dbo.LogsAuditoria (Fecha DESC);
GO

/* ---------- Datos semilla ---------- */
INSERT INTO dbo.Roles (Nombre) VALUES (N'Admin'), (N'Docente'), (N'Nutricionista'), (N'Estudiante');

-- Contraseña de todos: Innovare2026!  (PBKDF2-SHA256, 100.000 iteraciones)
DECLARE @hash NVARCHAR(300) = N'PBKDF2$100000$XcjD+560bsFwhPsHUi+XFg==$J/6Oqwph6Hz8GZtsTAjHnEZ669vaemtAqcFmqFbrGxA=';

INSERT INTO dbo.Usuarios (Nombre, Correo, PasswordHash, RolId)
SELECT s.Nombre, s.Correo, @hash, r.Id
FROM (VALUES
    (1,  N'Administrador del Sistema', N'admin@innovare.edu.bo',          N'Admin'),
    (2,  N'Lic. María Rojas',          N'nutricion@innovare.edu.bo',      N'Nutricionista'),
    (3,  N'Prof. Jorge Vargas',        N'jvargas@innovare.edu.bo',        N'Docente'),
    (4,  N'Prof. Lucía Torrez',        N'ltorrez@innovare.edu.bo',        N'Docente'),
    (5,  N'Ana Mamani',                N'ana.mamani@innovare.edu.bo',     N'Estudiante'),
    (6,  N'Luis Quispe',               N'luis.quispe@innovare.edu.bo',    N'Estudiante'),
    (7,  N'Carla Flores',              N'carla.flores@innovare.edu.bo',   N'Estudiante'),
    (8,  N'Diego Choque',              N'diego.choque@innovare.edu.bo',   N'Estudiante'),
    (9,  N'Sofía Gutiérrez',           N'sofia.gutierrez@innovare.edu.bo', N'Estudiante'),
    (10, N'Mateo Condori',             N'mateo.condori@innovare.edu.bo',  N'Estudiante')
) AS s (Orden, Nombre, Correo, Rol)
INNER JOIN dbo.Roles r ON r.Nombre = s.Rol
ORDER BY s.Orden;

INSERT INTO dbo.LogsAuditoria (UsuarioId, Accion, Entidad, Detalle)
VALUES (NULL, N'INSTALACION', N'Sistema', N'Instalación iniciada (script del Equipo 1).');
GO

/* Verificación */
SELECT 'Roles' AS Tabla, COUNT(*) AS Filas FROM dbo.Roles UNION ALL
SELECT 'Usuarios' AS Tabla, COUNT(*) AS Filas FROM dbo.Usuarios UNION ALL
SELECT 'LogsAuditoria' AS Tabla, COUNT(*) AS Filas FROM dbo.LogsAuditoria;
GO
