/* =====================================================================
   SmartNutriTracker - Colegio "Innovare"
   EQUIPO 5 - RECOMENDACIONES INTELIGENTES
   HU-23 a HU-26 · Objetivos, modelo según IMC, alimentos excluidos y recomendaciones
   Motor: SQL Server 2019+ / SQL Server Express

   ORDEN DE EJECUCIÓN (base nueva): Equipo1 → Equipo2 → Equipo3 → Equipo4 → Equipo5 → Equipo6
   Requiere: Equipos 1, 2, 3 y 4.
   ===================================================================== */

IF DB_ID(N'SmartNutriTrackerDB') IS NULL
BEGIN
    RAISERROR(N'La base SmartNutriTrackerDB no existe. Ejecute primero el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

USE SmartNutriTrackerDB;
GO

IF OBJECT_ID(N'dbo.RegistrosConsumo', N'U') IS NULL
BEGIN
    RAISERROR(N'Faltan los scripts de los Equipos 1 a 4.', 16, 1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID(N'dbo.Recomendaciones', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'Las tablas del Equipo 5 ya existen. Para reinstalar, vuelva a ejecutar desde el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE TABLE dbo.ObjetivosNutricionales
(
    Id                INT IDENTITY(1,1) CONSTRAINT PK_ObjetivosNutricionales PRIMARY KEY,
    Codigo            NVARCHAR(20)  NOT NULL CONSTRAINT UQ_Objetivos_Codigo UNIQUE,
    Nombre            NVARCHAR(60)  NOT NULL,
    AjustePorcentaje  DECIMAL(5,2)  NOT NULL CONSTRAINT CK_Objetivos_Ajuste CHECK (AjustePorcentaje BETWEEN -30 AND 30),
    PctProteina       DECIMAL(5,2)  NOT NULL,
    PctCarbohidratos  DECIMAL(5,2)  NOT NULL,
    PctGrasas         DECIMAL(5,2)  NOT NULL,
    Descripcion       NVARCHAR(300) NULL,
    CONSTRAINT CK_Objetivos_SumaMacros CHECK (PctProteina + PctCarbohidratos + PctGrasas = 100)
);

CREATE TABLE dbo.CategoriasImc
(
    Id                  INT IDENTITY(1,1) CONSTRAINT PK_CategoriasImc PRIMARY KEY,
    Nombre              NVARCHAR(40)  NOT NULL CONSTRAINT UQ_CategoriasImc_Nombre UNIQUE,
    ImcMin              DECIMAL(5,2)  NOT NULL,
    ImcMax              DECIMAL(5,2)  NOT NULL,
    ObjetivoSugeridoId  INT NOT NULL CONSTRAINT FK_CategoriasImc_Objetivo REFERENCES dbo.ObjetivosNutricionales(Id),
    Mensaje             NVARCHAR(300) NOT NULL,
    Activo              BIT NOT NULL CONSTRAINT DF_CategoriasImc_Activo DEFAULT (1),
    CONSTRAINT CK_CategoriasImc_Rango CHECK (ImcMin < ImcMax)
);

-- Relación N:M -> objetivos permitidos por categoría de IMC (1FN: sin listas en una columna)
CREATE TABLE dbo.CategoriaImcObjetivos
(
    CategoriaImcId  INT NOT NULL CONSTRAINT FK_CatImcObj_Categoria REFERENCES dbo.CategoriasImc(Id) ON DELETE CASCADE,
    ObjetivoId      INT NOT NULL CONSTRAINT FK_CatImcObj_Objetivo REFERENCES dbo.ObjetivosNutricionales(Id),
    CONSTRAINT PK_CategoriaImcObjetivos PRIMARY KEY (CategoriaImcId, ObjetivoId)
);
GO

/* ---------- Catálogo de objetivos con IDs fijos (los usa Estudiantes.ObjetivoId del Equipo 2) ---------- */
SET IDENTITY_INSERT dbo.ObjetivosNutricionales ON;
INSERT INTO dbo.ObjetivosNutricionales (Id, Codigo, Nombre, AjustePorcentaje, PctProteina, PctCarbohidratos, PctGrasas, Descripcion) VALUES
    (1, N'BAJAR',    N'Bajar de peso',  -15, 25, 45, 30, N'Déficit calórico moderado con más proteína para conservar masa muscular.'),
    (2, N'MANTENER', N'Mantener peso',    0, 20, 50, 30, N'Calorías iguales al gasto energético total.'),
    (3, N'GANAR',    N'Ganar peso',      10, 20, 55, 25, N'Superávit moderado con énfasis en carbohidratos complejos.');
SET IDENTITY_INSERT dbo.ObjetivosNutricionales OFF;
GO

-- Relación Estudiantes → ObjetivosNutricionales (columna creada por el Equipo 2)
ALTER TABLE dbo.Estudiantes WITH CHECK
    ADD CONSTRAINT FK_Estudiantes_Objetivo FOREIGN KEY (ObjetivoId) REFERENCES dbo.ObjetivosNutricionales(Id);
GO

CREATE TABLE dbo.AlimentosExcluidos
(
    EstudianteId  INT NOT NULL CONSTRAINT FK_Excluidos_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    AlimentoId    INT NOT NULL CONSTRAINT FK_Excluidos_Alimentos REFERENCES dbo.Alimentos(Id),
    Motivo        NVARCHAR(150) NULL,
    CONSTRAINT PK_AlimentosExcluidos PRIMARY KEY (EstudianteId, AlimentoId)
);

-- Se guardan los datos de entrada del cálculo (foto histórica). IMC, TMB, gasto
-- energético y totales del menú NO se guardan: se calculan (evita datos derivados).
CREATE TABLE dbo.Recomendaciones
(
    Id                      INT IDENTITY(1,1) CONSTRAINT PK_Recomendaciones PRIMARY KEY,
    EstudianteId            INT NOT NULL CONSTRAINT FK_Recomendaciones_Estudiantes REFERENCES dbo.Estudiantes(Id) ON DELETE CASCADE,
    Fecha                   DATE NOT NULL,
    PesoKg                  DECIMAL(5,2) NOT NULL,
    AlturaCm                DECIMAL(5,2) NOT NULL,
    Edad                    INT NOT NULL,
    FactorActividad         DECIMAL(4,3) NOT NULL,
    CategoriaImcId          INT NOT NULL CONSTRAINT FK_Recomendaciones_CatImc REFERENCES dbo.CategoriasImc(Id),
    ObjetivoSolicitadoId    INT NOT NULL CONSTRAINT FK_Recomendaciones_ObjSol REFERENCES dbo.ObjetivosNutricionales(Id),
    ObjetivoAplicadoId      INT NOT NULL CONSTRAINT FK_Recomendaciones_ObjApl REFERENCES dbo.ObjetivosNutricionales(Id),
    CaloriasObjetivo        DECIMAL(8,2) NOT NULL,
    ProteinasObjetivoG      DECIMAL(7,2) NOT NULL,
    CarbohidratosObjetivoG  DECIMAL(7,2) NOT NULL,
    GrasasObjetivoG         DECIMAL(7,2) NOT NULL,
    Estado                  NVARCHAR(20) NOT NULL CONSTRAINT DF_Recomendaciones_Estado DEFAULT (N'Generada')
                                CONSTRAINT CK_Recomendaciones_Estado CHECK (Estado IN (N'Generada', N'Aceptada', N'Rechazada')),
    ComentarioEstado        NVARCHAR(300) NULL,
    Semilla                 INT NOT NULL,
    CreadoPorId             INT NULL CONSTRAINT FK_Recomendaciones_Usuarios REFERENCES dbo.Usuarios(Id),
    FechaCreacion           DATETIME2 NOT NULL CONSTRAINT DF_Recomendaciones_Fecha DEFAULT (SYSUTCDATETIME())
);
CREATE INDEX IX_Recomendaciones_EstudianteFecha ON dbo.Recomendaciones (EstudianteId, Fecha DESC);

CREATE TABLE dbo.RecomendacionDetalles
(
    Id               INT IDENTITY(1,1) CONSTRAINT PK_RecomendacionDetalles PRIMARY KEY,
    RecomendacionId  INT NOT NULL CONSTRAINT FK_RecDetalles_Recomendaciones REFERENCES dbo.Recomendaciones(Id) ON DELETE CASCADE,
    TipoComidaId     INT NOT NULL CONSTRAINT FK_RecDetalles_TipoComida REFERENCES dbo.TiposComida(Id),
    AlimentoId       INT NOT NULL CONSTRAINT FK_RecDetalles_Alimentos REFERENCES dbo.Alimentos(Id),
    Porciones        DECIMAL(4,2) NOT NULL CONSTRAINT CK_RecDetalles_Porciones CHECK (Porciones > 0)
);

-- Observaciones como filas (1FN: nada de textos separados por comas)
CREATE TABLE dbo.RecomendacionObservaciones
(
    Id               INT IDENTITY(1,1) CONSTRAINT PK_RecomendacionObservaciones PRIMARY KEY,
    RecomendacionId  INT NOT NULL CONSTRAINT FK_RecObs_Recomendaciones REFERENCES dbo.Recomendaciones(Id) ON DELETE CASCADE,
    Orden            INT NOT NULL,
    Texto            NVARCHAR(400) NOT NULL
);
GO

-- Vista de apoyo (la usan los reportes del Equipo 2): IMC y categoría de cada estudiante
CREATE VIEW dbo.vw_EstudiantesImc
AS
SELECT  e.Id AS EstudianteId,
        e.Nombres + N' ' + e.Apellidos AS Estudiante,
        c.Nombre AS Curso,
        CAST(e.PesoKg / POWER(e.AlturaCm / 100.0, 2) AS DECIMAL(5,2)) AS Imc,
        ci.Nombre AS CategoriaImc
FROM dbo.Estudiantes e
INNER JOIN dbo.Cursos c ON c.Id = e.CursoId
LEFT JOIN dbo.CategoriasImc ci
       ON ci.Activo = 1
      AND e.PesoKg / POWER(e.AlturaCm / 100.0, 2) >= ci.ImcMin
      AND e.PesoKg / POWER(e.AlturaCm / 100.0, 2) <  ci.ImcMax
WHERE e.Activo = 1;
GO

/* ---------- Datos semilla ---------- */
INSERT INTO dbo.CategoriasImc (Nombre, ImcMin, ImcMax, ObjetivoSugeridoId, Mensaje)
SELECT s.Nombre, s.ImcMin, s.ImcMax, o.Id, s.Mensaje
FROM (VALUES
    (1, N'Bajo peso',  0.00, 18.50, N'GANAR',    N'IMC bajo: no se recomienda déficit calórico; se prioriza ganar o mantener peso.'),
    (2, N'Normal',    18.50, 25.00, N'MANTENER', N'IMC dentro del rango saludable.'),
    (3, N'Sobrepeso', 25.00, 30.00, N'BAJAR',    N'IMC elevado: no se recomienda superávit calórico.'),
    (4, N'Obesidad',  30.00, 99.99, N'BAJAR',    N'IMC muy elevado: reducción gradual y seguimiento con el nutricionista.')
) AS s (Orden, Nombre, ImcMin, ImcMax, Objetivo, Mensaje)
INNER JOIN dbo.ObjetivosNutricionales o ON o.Codigo = s.Objetivo
ORDER BY s.Orden;

INSERT INTO dbo.CategoriaImcObjetivos (CategoriaImcId, ObjetivoId)
SELECT c.Id, o.Id
FROM (VALUES
    (N'Bajo peso', N'GANAR'), (N'Bajo peso', N'MANTENER'),
    (N'Normal', N'BAJAR'), (N'Normal', N'MANTENER'), (N'Normal', N'GANAR'),
    (N'Sobrepeso', N'BAJAR'), (N'Sobrepeso', N'MANTENER'),
    (N'Obesidad', N'BAJAR')
) AS s (Categoria, Objetivo)
INNER JOIN dbo.CategoriasImc c ON c.Nombre = s.Categoria
INNER JOIN dbo.ObjetivosNutricionales o ON o.Codigo = s.Objetivo;

INSERT INTO dbo.AlimentosExcluidos (EstudianteId, AlimentoId, Motivo)
SELECT e.Id, a.Id, N'Alergia'
FROM dbo.Estudiantes e CROSS JOIN dbo.Alimentos a
WHERE e.Nombres = N'Carla' AND a.Nombre = N'Maní tostado sin sal';
GO


/* Verificación */
SELECT 'ObjetivosNutricionales' AS Tabla, COUNT(*) AS Filas FROM dbo.ObjetivosNutricionales UNION ALL
SELECT 'CategoriasImc' AS Tabla, COUNT(*) AS Filas FROM dbo.CategoriasImc UNION ALL
SELECT 'CategoriaImcObjetivos' AS Tabla, COUNT(*) AS Filas FROM dbo.CategoriaImcObjetivos UNION ALL
SELECT 'AlimentosExcluidos' AS Tabla, COUNT(*) AS Filas FROM dbo.AlimentosExcluidos UNION ALL
SELECT 'Recomendaciones' AS Tabla, COUNT(*) AS Filas FROM dbo.Recomendaciones;
GO

SET NOEXEC OFF;
GO
