/* =====================================================================
   SmartNutriTracker - Colegio "Innovare"
   EQUIPO 4 - REGISTRO DE HÁBITOS
   HU-19 a HU-22 · Consumo real de alimentos y hábitos diarios (sueño, agua, actividad)
   Motor: SQL Server 2019+ / SQL Server Express

   ORDEN DE EJECUCIÓN (base nueva): Equipo1 → Equipo2 → Equipo3 → Equipo4 → Equipo5 → Equipo6
   Requiere: Equipos 1, 2 y 3.
   ===================================================================== */

IF DB_ID(N'SmartNutriTrackerDB') IS NULL
BEGIN
    RAISERROR(N'La base SmartNutriTrackerDB no existe. Ejecute primero el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

USE SmartNutriTrackerDB;
GO

IF OBJECT_ID(N'dbo.Alimentos', N'U') IS NULL
BEGIN
    RAISERROR(N'Faltan los scripts de los Equipos 1, 2 y 3.', 16, 1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID(N'dbo.RegistrosConsumo', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'Las tablas del Equipo 4 ya existen. Para reinstalar, vuelva a ejecutar desde el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE TABLE dbo.RegistrosConsumo
(
    Id             INT IDENTITY(1,1) CONSTRAINT PK_RegistrosConsumo PRIMARY KEY,
    EstudianteId   INT NOT NULL CONSTRAINT FK_Consumo_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    Fecha          DATE NOT NULL,
    TipoComidaId   INT NOT NULL CONSTRAINT FK_Consumo_TipoComida REFERENCES dbo.TiposComida(Id),
    AlimentoId     INT NOT NULL CONSTRAINT FK_Consumo_Alimentos REFERENCES dbo.Alimentos(Id),
    Porciones      DECIMAL(4,2) NOT NULL CONSTRAINT CK_Consumo_Porciones CHECK (Porciones > 0 AND Porciones <= 10),
    FechaRegistro  DATETIME2 NOT NULL CONSTRAINT DF_Consumo_Fecha DEFAULT (SYSUTCDATETIME())
);
CREATE INDEX IX_Consumo_EstudianteFecha ON dbo.RegistrosConsumo (EstudianteId, Fecha);

CREATE TABLE dbo.RegistrosHabitos
(
    Id                INT IDENTITY(1,1) CONSTRAINT PK_RegistrosHabitos PRIMARY KEY,
    EstudianteId      INT NOT NULL CONSTRAINT FK_Habitos_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    Fecha             DATE NOT NULL,
    HorasSueno        DECIMAL(4,2) NOT NULL CONSTRAINT CK_Habitos_Sueno CHECK (HorasSueno BETWEEN 0 AND 24),
    AguaMl            INT NOT NULL CONSTRAINT CK_Habitos_Agua CHECK (AguaMl BETWEEN 0 AND 10000),
    MinutosActividad  INT NOT NULL CONSTRAINT CK_Habitos_Actividad CHECK (MinutosActividad BETWEEN 0 AND 1440),
    Observaciones     NVARCHAR(300) NULL,
    CONSTRAINT UQ_Habitos_EstudianteFecha UNIQUE (EstudianteId, Fecha)
);
GO

-- Vista de apoyo: totales nutricionales por estudiante y día
CREATE VIEW dbo.vw_ConsumoDiario
AS
SELECT  rc.EstudianteId,
        rc.Fecha,
        SUM(a.Calorias      * rc.Porciones) AS Calorias,
        SUM(a.Proteinas     * rc.Porciones) AS Proteinas,
        SUM(a.Carbohidratos * rc.Porciones) AS Carbohidratos,
        SUM(a.Grasas        * rc.Porciones) AS Grasas,
        SUM(a.Azucares      * rc.Porciones) AS Azucares,
        SUM(a.SodioMg       * rc.Porciones) AS SodioMg
FROM dbo.RegistrosConsumo rc
INNER JOIN dbo.Alimentos a ON a.Id = rc.AlimentoId
GROUP BY rc.EstudianteId, rc.Fecha;
GO

/* ---------- Datos semilla: últimos 7 días de Luis, Carla y Diego ---------- */
;WITH Dias AS (SELECT n FROM (VALUES (1),(2),(3),(4),(5),(6),(7)) AS t(n))
INSERT INTO dbo.RegistrosConsumo (EstudianteId, Fecha, TipoComidaId, AlimentoId, Porciones)
SELECT e.Id, DATEADD(DAY, -d.n, CAST(GETDATE() AS DATE)), t.Id, a.Id, p.Porciones
FROM Dias d
CROSS JOIN (VALUES
    (N'Luis',  N'Desayuno', N'Leche semidescremada', 2.0), (N'Luis', N'Desayuno', N'Avena cocida', 2.0),
    (N'Luis',  N'Almuerzo', N'Pechuga de pollo a la plancha', 2.0), (N'Luis', N'Almuerzo', N'Quinua cocida', 2.0),
    (N'Luis',  N'Merienda tarde', N'Plátano', 1.0), (N'Luis', N'Cena', N'Trucha al horno', 1.5),
    (N'Luis',  N'Cena', N'Arroz blanco cocido', 1.5),
    (N'Carla', N'Desayuno', N'Marraqueta', 2.0), (N'Carla', N'Desayuno', N'Gaseosa', 1.0),
    (N'Carla', N'Merienda mañana', N'Salteña', 1.0), (N'Carla', N'Almuerzo', N'Carne de res magra', 1.5),
    (N'Carla', N'Almuerzo', N'Arroz blanco cocido', 2.0), (N'Carla', N'Merienda tarde', N'Papas fritas de bolsa', 1.0),
    (N'Diego', N'Desayuno', N'Pan integral', 1.0), (N'Diego', N'Almuerzo', N'Lentejas guisadas', 1.0),
    (N'Diego', N'Cena', N'Ensalada mixta', 1.0)
) AS p (Estudiante, TipoComida, Alimento, Porciones)
INNER JOIN dbo.Estudiantes e ON e.Nombres = p.Estudiante
INNER JOIN dbo.TiposComida t ON t.Nombre = p.TipoComida
INNER JOIN dbo.Alimentos a ON a.Nombre = p.Alimento;

;WITH Dias AS (SELECT n FROM (VALUES (1),(2),(3),(4),(5),(6),(7)) AS t(n))
INSERT INTO dbo.RegistrosHabitos (EstudianteId, Fecha, HorasSueno, AguaMl, MinutosActividad, Observaciones)
SELECT e.Id, DATEADD(DAY, -d.n, CAST(GETDATE() AS DATE)),
       h.Sueno + (d.n % 2) * 0.5, h.Agua + (d.n % 3) * 150, h.Actividad + (d.n % 2) * 10, NULL
FROM Dias d
CROSS JOIN (VALUES
    (N'Luis',  8.0, 2200, 60),
    (N'Carla', 6.0, 900,  10),
    (N'Diego', 7.0, 1600, 30)
) AS h (Estudiante, Sueno, Agua, Actividad)
INNER JOIN dbo.Estudiantes e ON e.Nombres = h.Estudiante;
GO


/* Verificación */
SELECT 'RegistrosConsumo' AS Tabla, COUNT(*) AS Filas FROM dbo.RegistrosConsumo UNION ALL
SELECT 'RegistrosHabitos' AS Tabla, COUNT(*) AS Filas FROM dbo.RegistrosHabitos;
GO

SET NOEXEC OFF;
GO
