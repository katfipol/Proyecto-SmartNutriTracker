/* =====================================================================
   SmartNutriTracker - Colegio "Innovare"
   EQUIPO 6 - NOTIFICACIONES Y TESTING
   HU-27, HU-28 · Tipos de alerta, alertas, notificaciones internas y citas nutricionales
   Motor: SQL Server 2019+ / SQL Server Express

   ORDEN DE EJECUCIÓN (base nueva): Equipo1 → Equipo2 → Equipo3 → Equipo4 → Equipo5 → Equipo6
   Requiere: Equipos 1 a 5. Es el último script: deja el sistema completo.
   ===================================================================== */

IF DB_ID(N'SmartNutriTrackerDB') IS NULL
BEGIN
    RAISERROR(N'La base SmartNutriTrackerDB no existe. Ejecute primero el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

USE SmartNutriTrackerDB;
GO

IF OBJECT_ID(N'dbo.Recomendaciones', N'U') IS NULL
BEGIN
    RAISERROR(N'Faltan los scripts de los Equipos 1 a 5.', 16, 1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID(N'dbo.Alertas', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'Las tablas del Equipo 6 ya existen. Para reinstalar, vuelva a ejecutar desde el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE TABLE dbo.TiposAlerta
(
    Id           INT IDENTITY(1,1) CONSTRAINT PK_TiposAlerta PRIMARY KEY,
    Codigo       NVARCHAR(30)  NOT NULL CONSTRAINT UQ_TiposAlerta_Codigo UNIQUE,
    Nombre       NVARCHAR(80)  NOT NULL,
    Descripcion  NVARCHAR(300) NULL,
    Umbral       DECIMAL(10,2) NOT NULL,
    Unidad       NVARCHAR(20)  NOT NULL,
    Nivel        NVARCHAR(10)  NOT NULL CONSTRAINT CK_TiposAlerta_Nivel CHECK (Nivel IN (N'Baja', N'Media', N'Alta')),
    Activo       BIT NOT NULL CONSTRAINT DF_TiposAlerta_Activo DEFAULT (1)
);

CREATE TABLE dbo.Alertas
(
    Id               INT IDENTITY(1,1) CONSTRAINT PK_Alertas PRIMARY KEY,
    EstudianteId     INT NOT NULL CONSTRAINT FK_Alertas_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    TipoAlertaId     INT NOT NULL CONSTRAINT FK_Alertas_Tipo REFERENCES dbo.TiposAlerta(Id),
    Fecha            DATE NOT NULL,
    ValorRegistrado  DECIMAL(10,2) NOT NULL,
    Mensaje          NVARCHAR(400) NOT NULL,
    Atendida         BIT NOT NULL CONSTRAINT DF_Alertas_Atendida DEFAULT (0),
    AtendidaPorId    INT NULL CONSTRAINT FK_Alertas_Usuarios REFERENCES dbo.Usuarios(Id),
    FechaAtencion    DATETIME2 NULL,
    FechaCreacion    DATETIME2 NOT NULL CONSTRAINT DF_Alertas_Fecha DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT UQ_Alertas_EstudianteTipoFecha UNIQUE (EstudianteId, TipoAlertaId, Fecha)
);

CREATE TABLE dbo.Notificaciones
(
    Id             INT IDENTITY(1,1) CONSTRAINT PK_Notificaciones PRIMARY KEY,
    UsuarioId      INT NOT NULL CONSTRAINT FK_Notificaciones_Usuarios REFERENCES dbo.Usuarios(Id) ON DELETE CASCADE,
    Titulo         NVARCHAR(100) NOT NULL,
    Mensaje        NVARCHAR(400) NOT NULL,
    Tipo           NVARCHAR(20)  NOT NULL CONSTRAINT CK_Notificaciones_Tipo CHECK (Tipo IN (N'Recordatorio', N'Alerta', N'Cita', N'Sistema')),
    Leida          BIT NOT NULL CONSTRAINT DF_Notificaciones_Leida DEFAULT (0),
    FechaCreacion  DATETIME2 NOT NULL CONSTRAINT DF_Notificaciones_Fecha DEFAULT (SYSUTCDATETIME())
);
CREATE INDEX IX_Notificaciones_Usuario ON dbo.Notificaciones (UsuarioId, Leida, FechaCreacion DESC);

CREATE TABLE dbo.Citas
(
    Id                   INT IDENTITY(1,1) CONSTRAINT PK_Citas PRIMARY KEY,
    EstudianteId         INT NOT NULL CONSTRAINT FK_Citas_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    NutricionistaId      INT NOT NULL CONSTRAINT FK_Citas_Nutricionista REFERENCES dbo.Usuarios(Id),
    FechaHora            DATETIME2 NOT NULL,
    DuracionMinutos      INT NOT NULL CONSTRAINT DF_Citas_Duracion DEFAULT (30) CONSTRAINT CK_Citas_Duracion CHECK (DuracionMinutos BETWEEN 10 AND 240),
    Motivo               NVARCHAR(200) NOT NULL,
    Estado               NVARCHAR(20)  NOT NULL CONSTRAINT DF_Citas_Estado DEFAULT (N'Programada')
                             CONSTRAINT CK_Citas_Estado CHECK (Estado IN (N'Programada', N'Completada', N'Cancelada')),
    Notas                NVARCHAR(500) NULL,
    RecordatorioEnviado  BIT NOT NULL CONSTRAINT DF_Citas_Recordatorio DEFAULT (0),
    FechaCreacion        DATETIME2 NOT NULL CONSTRAINT DF_Citas_Fecha DEFAULT (SYSUTCDATETIME())
);
CREATE INDEX IX_Citas_FechaHora ON dbo.Citas (FechaHora);
GO

/* ---------- Datos semilla ---------- */
INSERT INTO dbo.TiposAlerta (Codigo, Nombre, Descripcion, Umbral, Unidad, Nivel) VALUES
    (N'CALORIAS_EXCESO', N'Exceso de calorías',     N'Consumo del día por encima del % indicado del objetivo calórico.', 130,  N'%',   N'Media'),
    (N'CALORIAS_DEFICIT', N'Déficit de calorías',   N'Consumo del día por debajo del % indicado del objetivo calórico.',  50,  N'%',   N'Media'),
    (N'AZUCAR_EXCESO',   N'Exceso de azúcar',       N'Azúcares del día por encima del límite.',                          50,  N'g',   N'Alta'),
    (N'SODIO_EXCESO',    N'Exceso de sodio',        N'Sodio del día por encima del límite.',                           2300,  N'mg',  N'Media'),
    (N'AGUA_BAJA',       N'Consumo de agua bajo',   N'Agua del día por debajo del mínimo.',                            1500,  N'ml',  N'Baja'),
    (N'SUENO_BAJO',      N'Pocas horas de sueño',   N'Horas de sueño por debajo del mínimo.',                             7,  N'h',   N'Media'),
    (N'ACTIVIDAD_BAJA',  N'Actividad física baja',  N'Minutos de actividad por debajo del mínimo.',                      30,  N'min', N'Baja'),
    (N'IMC_RIESGO',      N'IMC en zona de riesgo',  N'IMC en categoría Bajo peso u Obesidad.',                            0,  N'IMC', N'Alta');

-- Cita nutricional de ejemplo (mañana a las 10:00)
INSERT INTO dbo.Citas (EstudianteId, NutricionistaId, FechaHora, DuracionMinutos, Motivo)
SELECT e.Id, u.Id, DATEADD(HOUR, 10, CAST(DATEADD(DAY, 1, CAST(GETDATE() AS DATE)) AS DATETIME2)), 30, N'Control de hábitos y revisión de alimentación'
FROM dbo.Estudiantes e CROSS JOIN dbo.Usuarios u
WHERE e.Nombres = N'Carla' AND u.Correo = N'nutricion@innovare.edu.bo';

INSERT INTO dbo.Notificaciones (UsuarioId, Titulo, Mensaje, Tipo)
SELECT Id, N'Bienvenido a SmartNutriTracker', N'Registra tus comidas y hábitos cada día para recibir recomendaciones.', N'Sistema'
FROM dbo.Usuarios;

INSERT INTO dbo.LogsAuditoria (UsuarioId, Accion, Entidad, Detalle)
VALUES (NULL, N'INSTALACION', N'Sistema', N'Base de datos completa (scripts de los 6 equipos).');
GO


/* Verificación */
SELECT 'TiposAlerta' AS Tabla, COUNT(*) AS Filas FROM dbo.TiposAlerta UNION ALL
SELECT 'Alertas' AS Tabla, COUNT(*) AS Filas FROM dbo.Alertas UNION ALL
SELECT 'Notificaciones' AS Tabla, COUNT(*) AS Filas FROM dbo.Notificaciones UNION ALL
SELECT 'Citas' AS Tabla, COUNT(*) AS Filas FROM dbo.Citas;
GO

SET NOEXEC OFF;
GO
