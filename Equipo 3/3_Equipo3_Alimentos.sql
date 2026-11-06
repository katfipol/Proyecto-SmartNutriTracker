/* =====================================================================
   SmartNutriTracker - Colegio "Innovare"
   EQUIPO 3 - GESTIÓN DE ALIMENTOS
   HU-14 a HU-17 · Catálogo de alimentos, categorías, tiempos de comida y menús diarios
   Motor: SQL Server 2019+ / SQL Server Express

   ORDEN DE EJECUCIÓN (base nueva): Equipo1 → Equipo2 → Equipo3 → Equipo4 → Equipo5 → Equipo6
   Requiere: Equipos 1 y 2.
   ===================================================================== */

IF DB_ID(N'SmartNutriTrackerDB') IS NULL
BEGIN
    RAISERROR(N'La base SmartNutriTrackerDB no existe. Ejecute primero el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

USE SmartNutriTrackerDB;
GO

IF OBJECT_ID(N'dbo.Estudiantes', N'U') IS NULL
BEGIN
    RAISERROR(N'Faltan los scripts de los Equipos 1 y 2.', 16, 1);
    SET NOEXEC ON;
END
GO

IF OBJECT_ID(N'dbo.Alimentos', N'U') IS NOT NULL
BEGIN
    RAISERROR(N'Las tablas del Equipo 3 ya existen. Para reinstalar, vuelva a ejecutar desde el script del Equipo 1.', 16, 1);
    SET NOEXEC ON;
END
GO

CREATE TABLE dbo.CategoriasAlimento
(
    Id      INT IDENTITY(1,1) CONSTRAINT PK_CategoriasAlimento PRIMARY KEY,
    Codigo  NVARCHAR(30) NOT NULL CONSTRAINT UQ_CategoriasAlimento_Codigo UNIQUE,
    Nombre  NVARCHAR(60) NOT NULL
);

CREATE TABLE dbo.TiposComida
(
    Id                  INT IDENTITY(1,1) CONSTRAINT PK_TiposComida PRIMARY KEY,
    Nombre              NVARCHAR(30) NOT NULL CONSTRAINT UQ_TiposComida_Nombre UNIQUE,
    Orden               INT NOT NULL,
    PorcentajeCalorias  DECIMAL(5,2) NOT NULL CONSTRAINT CK_TiposComida_Pct CHECK (PorcentajeCalorias > 0 AND PorcentajeCalorias <= 100)
);

-- Plantilla del motor de recomendaciones: categorías que lleva cada comida
CREATE TABLE dbo.TipoComidaCategorias
(
    TipoComidaId         INT NOT NULL CONSTRAINT FK_TCC_TipoComida REFERENCES dbo.TiposComida(Id) ON DELETE CASCADE,
    CategoriaAlimentoId  INT NOT NULL CONSTRAINT FK_TCC_Categoria REFERENCES dbo.CategoriasAlimento(Id),
    Orden                INT NOT NULL,
    CONSTRAINT PK_TipoComidaCategorias PRIMARY KEY (TipoComidaId, CategoriaAlimentoId)
);

CREATE TABLE dbo.Alimentos
(
    Id                   INT IDENTITY(1,1) CONSTRAINT PK_Alimentos PRIMARY KEY,
    Nombre               NVARCHAR(120) NOT NULL CONSTRAINT UQ_Alimentos_Nombre UNIQUE,
    CategoriaAlimentoId  INT NOT NULL CONSTRAINT FK_Alimentos_Categoria REFERENCES dbo.CategoriasAlimento(Id),
    PorcionDescripcion   NVARCHAR(60) NOT NULL,
    PorcionGramos        DECIMAL(7,2) NOT NULL CONSTRAINT CK_Alimentos_Gramos CHECK (PorcionGramos > 0),
    Calorias             DECIMAL(7,2) NOT NULL CONSTRAINT CK_Alimentos_Calorias CHECK (Calorias >= 0),
    Proteinas            DECIMAL(7,2) NOT NULL CONSTRAINT CK_Alimentos_Prot CHECK (Proteinas >= 0),
    Carbohidratos        DECIMAL(7,2) NOT NULL CONSTRAINT CK_Alimentos_Carb CHECK (Carbohidratos >= 0),
    Grasas               DECIMAL(7,2) NOT NULL CONSTRAINT CK_Alimentos_Gras CHECK (Grasas >= 0),
    Fibra                DECIMAL(7,2) NOT NULL CONSTRAINT DF_Alimentos_Fibra DEFAULT (0),
    Azucares             DECIMAL(7,2) NOT NULL CONSTRAINT DF_Alimentos_Azucar DEFAULT (0),
    SodioMg              DECIMAL(7,2) NOT NULL CONSTRAINT DF_Alimentos_Sodio DEFAULT (0),
    Activo               BIT NOT NULL CONSTRAINT DF_Alimentos_Activo DEFAULT (1)
);

CREATE TABLE dbo.MenusDiarios
(
    Id             INT IDENTITY(1,1) CONSTRAINT PK_MenusDiarios PRIMARY KEY,
    Nombre         NVARCHAR(100) NOT NULL,
    Fecha          DATE NULL,
    Descripcion    NVARCHAR(300) NULL,
    CreadoPorId    INT NOT NULL CONSTRAINT FK_Menus_Usuarios REFERENCES dbo.Usuarios(Id),
    FechaCreacion  DATETIME2 NOT NULL CONSTRAINT DF_Menus_Fecha DEFAULT (SYSUTCDATETIME())
);

CREATE TABLE dbo.MenuDetalles
(
    Id            INT IDENTITY(1,1) CONSTRAINT PK_MenuDetalles PRIMARY KEY,
    MenuId        INT NOT NULL CONSTRAINT FK_MenuDetalles_Menus REFERENCES dbo.MenusDiarios(Id) ON DELETE CASCADE,
    TipoComidaId  INT NOT NULL CONSTRAINT FK_MenuDetalles_TipoComida REFERENCES dbo.TiposComida(Id),
    AlimentoId    INT NOT NULL CONSTRAINT FK_MenuDetalles_Alimentos REFERENCES dbo.Alimentos(Id),
    Porciones     DECIMAL(4,2) NOT NULL CONSTRAINT CK_MenuDetalles_Porciones CHECK (Porciones > 0)
);
GO

/* ---------- Datos semilla ---------- */
INSERT INTO dbo.CategoriasAlimento (Codigo, Nombre) VALUES
    (N'LACTEO',          N'Lácteos y bebidas lácteas'),
    (N'CEREAL',          N'Cereales y tubérculos'),
    (N'FRUTA',           N'Frutas'),
    (N'VERDURA',         N'Verduras'),
    (N'PROTEINA',        N'Carnes, huevos y legumbres'),
    (N'GRASA_SALUDABLE', N'Grasas saludables y frutos secos'),
    (N'BEBIDA',          N'Bebidas'),
    (N'SNACK',           N'Comida rápida y snacks');

INSERT INTO dbo.TiposComida (Nombre, Orden, PorcentajeCalorias) VALUES
    (N'Desayuno',        1, 25),
    (N'Merienda mañana', 2, 10),
    (N'Almuerzo',        3, 35),
    (N'Merienda tarde',  4, 10),
    (N'Cena',            5, 20);

INSERT INTO dbo.TipoComidaCategorias (TipoComidaId, CategoriaAlimentoId, Orden)
SELECT t.Id, c.Id, s.Orden
FROM (VALUES
    (N'Desayuno', N'LACTEO', 1), (N'Desayuno', N'CEREAL', 2), (N'Desayuno', N'FRUTA', 3),
    (N'Merienda mañana', N'FRUTA', 1), (N'Merienda mañana', N'GRASA_SALUDABLE', 2),
    (N'Almuerzo', N'PROTEINA', 1), (N'Almuerzo', N'CEREAL', 2), (N'Almuerzo', N'VERDURA', 3), (N'Almuerzo', N'FRUTA', 4),
    (N'Merienda tarde', N'LACTEO', 1), (N'Merienda tarde', N'FRUTA', 2),
    (N'Cena', N'PROTEINA', 1), (N'Cena', N'VERDURA', 2), (N'Cena', N'CEREAL', 3)
) AS s (TipoComida, Categoria, Orden)
INNER JOIN dbo.TiposComida t ON t.Nombre = s.TipoComida
INNER JOIN dbo.CategoriasAlimento c ON c.Codigo = s.Categoria;

INSERT INTO dbo.Alimentos (Nombre, CategoriaAlimentoId, PorcionDescripcion, PorcionGramos, Calorias, Proteinas, Carbohidratos, Grasas, Fibra, Azucares, SodioMg)
SELECT s.Nombre, c.Id, s.Porcion, s.Gramos, s.Kcal, s.Prot, s.Carb, s.Gras, s.Fibra, s.Azucar, s.Sodio
FROM (VALUES
    (N'Leche semidescremada',          N'LACTEO', N'1 taza (240 ml)',          240, 120,  8.0, 12.0,  4.5,  0.0, 12.0, 105),
    (N'Yogur natural',                 N'LACTEO', N'1 vaso (200 g)',           200, 122,  7.0, 14.0,  4.0,  0.0, 14.0,  92),
    (N'Queso fresco',                  N'LACTEO', N'2 rebanadas (50 g)',        50, 132,  9.0,  1.5, 10.0,  0.0,  0.5, 230),
    (N'Api de maíz morado',            N'LACTEO', N'1 vaso (250 ml)',          250, 160,  4.0, 32.0,  2.0,  1.0, 18.0,  40),
    (N'Leche con quinua',              N'LACTEO', N'1 taza (250 ml)',          250, 180,  8.5, 26.0,  4.5,  1.5, 14.0, 110),
    (N'Pan integral',                  N'CEREAL', N'2 rebanadas (60 g)',        60, 150,  6.0, 26.0,  2.0,  4.0,  3.0, 270),
    (N'Avena cocida',                  N'CEREAL', N'1 taza (240 g)',           240, 160,  6.0, 27.0,  3.0,  4.0,  1.0,  10),
    (N'Arroz blanco cocido',           N'CEREAL', N'1 taza (160 g)',           160, 205,  4.3, 45.0,  0.4,  0.6,  0.0,   2),
    (N'Quinua cocida',                 N'CEREAL', N'1 taza (185 g)',           185, 222,  8.0, 39.0,  3.5,  5.0,  1.6,  13),
    (N'Papa cocida',                   N'CEREAL', N'1 unidad mediana (150 g)', 150, 130,  3.0, 30.0,  0.2,  2.5,  1.3,   8),
    (N'Fideo integral cocido',         N'CEREAL', N'1 taza (140 g)',           140, 174,  7.5, 37.0,  0.8,  6.0,  1.0,   4),
    (N'Marraqueta',                    N'CEREAL', N'1 unidad (70 g)',           70, 190,  6.0, 38.0,  1.5,  1.5,  1.5, 380),
    (N'Manzana',                       N'FRUTA',  N'1 unidad mediana (180 g)', 180,  95,  0.5, 25.0,  0.3,  4.4, 19.0,   2),
    (N'Plátano',                       N'FRUTA',  N'1 unidad mediana (120 g)', 120, 105,  1.3, 27.0,  0.4,  3.1, 14.0,   1),
    (N'Naranja',                       N'FRUTA',  N'1 unidad mediana (130 g)', 130,  62,  1.2, 15.0,  0.2,  3.1, 12.0,   0),
    (N'Papaya',                        N'FRUTA',  N'1 taza en cubos (145 g)',  145,  62,  0.7, 16.0,  0.4,  2.5, 11.0,  12),
    (N'Mandarina',                     N'FRUTA',  N'2 unidades (150 g)',       150,  80,  1.2, 20.0,  0.5,  2.7, 16.0,   3),
    (N'Frutilla',                      N'FRUTA',  N'1 taza (150 g)',           150,  48,  1.0, 11.5,  0.5,  3.0,  7.0,   2),
    (N'Ensalada mixta',                N'VERDURA', N'1 plato (150 g)',         150,  30,  1.5,  6.0,  0.3,  2.0,  3.5,  15),
    (N'Brócoli al vapor',              N'VERDURA', N'1 taza (150 g)',          150,  52,  4.2, 10.0,  0.6,  5.0,  2.0,  48),
    (N'Zanahoria cocida',              N'VERDURA', N'1 taza (150 g)',          150,  54,  1.2, 12.5,  0.3,  4.5,  5.0,  90),
    (N'Vainitas salteadas',            N'VERDURA', N'1 taza (125 g)',          125,  44,  2.4,  9.8,  0.3,  4.0,  2.0,   6),
    (N'Sopa de verduras',              N'VERDURA', N'1 plato (300 ml)',        300,  90,  3.0, 15.0,  2.0,  3.5,  4.0, 450),
    (N'Pechuga de pollo a la plancha', N'PROTEINA', N'1 filete (120 g)',       120, 198, 37.0,  0.0,  4.3,  0.0,  0.0,  88),
    (N'Huevo duro',                    N'PROTEINA', N'2 unidades (100 g)',     100, 155, 13.0,  1.1, 10.6,  0.0,  1.1, 124),
    (N'Carne de res magra',            N'PROTEINA', N'1 porción (110 g)',      110, 200, 29.0,  0.0,  9.0,  0.0,  0.0,  66),
    (N'Trucha al horno',               N'PROTEINA', N'1 filete (120 g)',       120, 170, 25.0,  0.0,  7.5,  0.0,  0.0,  62),
    (N'Lentejas guisadas',             N'PROTEINA', N'1 taza (200 g)',         200, 230, 18.0, 40.0,  0.8, 15.6,  3.6,   8),
    (N'Atún en agua',                  N'PROTEINA', N'1 lata escurrida (120 g)', 120, 140, 30.0, 0.0, 1.2,  0.0,  0.0, 380),
    (N'Maní tostado sin sal',          N'GRASA_SALUDABLE', N'1 puñado (30 g)', 30, 170,  7.0,  6.0, 14.0,  2.5,  1.2,   2),
    (N'Almendras',                     N'GRASA_SALUDABLE', N'1 puñado (28 g)', 28, 164,  6.0,  6.0, 14.0,  3.5,  1.2,   0),
    (N'Palta',                         N'GRASA_SALUDABLE', N'1/2 unidad (70 g)', 70, 112, 1.4,  6.0, 10.3,  4.7,  0.5,   5),
    -- Alimentos poco saludables (para probar alertas)
    (N'Salteña',                       N'SNACK',  N'1 unidad (150 g)',         150, 380, 12.0, 40.0, 19.0,  1.5,  6.0, 650),
    (N'Gaseosa',                       N'BEBIDA', N'1 vaso (500 ml)',          500, 210,  0.0, 53.0,  0.0,  0.0, 53.0,  45),
    (N'Papas fritas de bolsa',         N'SNACK',  N'1 bolsa (60 g)',            60, 320,  4.0, 32.0, 20.0,  2.5,  0.5, 380)
) AS s (Nombre, Categoria, Porcion, Gramos, Kcal, Prot, Carb, Gras, Fibra, Azucar, Sodio)
INNER JOIN dbo.CategoriasAlimento c ON c.Codigo = s.Categoria;

-- BEBIDA y SNACK no están en la plantilla de comidas, así que el motor de
-- recomendaciones nunca los sugiere; solo sirven para registrar el consumo real.

-- Menú diario de ejemplo creado por la nutricionista (HU-16)
INSERT INTO dbo.MenusDiarios (Nombre, Fecha, Descripcion, CreadoPorId)
VALUES (N'Menú escolar balanceado', CAST(GETDATE() AS DATE), N'Menú base del comedor escolar.',
        (SELECT Id FROM dbo.Usuarios WHERE Correo = N'nutricion@innovare.edu.bo'));

INSERT INTO dbo.MenuDetalles (MenuId, TipoComidaId, AlimentoId, Porciones)
SELECT m.Id, t.Id, a.Id, s.Porciones
FROM (VALUES
    (N'Desayuno', N'Leche con quinua', 1.0), (N'Desayuno', N'Pan integral', 1.0), (N'Desayuno', N'Papaya', 1.0),
    (N'Almuerzo', N'Sopa de verduras', 1.0), (N'Almuerzo', N'Pechuga de pollo a la plancha', 1.0),
    (N'Almuerzo', N'Arroz blanco cocido', 1.0), (N'Almuerzo', N'Ensalada mixta', 1.0),
    (N'Merienda tarde', N'Yogur natural', 1.0), (N'Merienda tarde', N'Manzana', 1.0)
) AS s (TipoComida, Alimento, Porciones)
CROSS JOIN (SELECT TOP (1) Id FROM dbo.MenusDiarios ORDER BY Id) AS m
INNER JOIN dbo.TiposComida t ON t.Nombre = s.TipoComida
INNER JOIN dbo.Alimentos a ON a.Nombre = s.Alimento;
GO


/* Verificación */
SELECT 'CategoriasAlimento' AS Tabla, COUNT(*) AS Filas FROM dbo.CategoriasAlimento UNION ALL
SELECT 'TiposComida' AS Tabla, COUNT(*) AS Filas FROM dbo.TiposComida UNION ALL
SELECT 'TipoComidaCategorias' AS Tabla, COUNT(*) AS Filas FROM dbo.TipoComidaCategorias UNION ALL
SELECT 'Alimentos' AS Tabla, COUNT(*) AS Filas FROM dbo.Alimentos UNION ALL
SELECT 'MenusDiarios' AS Tabla, COUNT(*) AS Filas FROM dbo.MenusDiarios UNION ALL
SELECT 'MenuDetalles' AS Tabla, COUNT(*) AS Filas FROM dbo.MenuDetalles;
GO

SET NOEXEC OFF;
GO
