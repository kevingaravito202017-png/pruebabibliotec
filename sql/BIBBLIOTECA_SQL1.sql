-- =====================================================
-- SISTEMA DE GESTIÓN DE BIBLIOTECA
-- Base de datos optimizada para grandes volúmenes
-- MySQL Workbench - VERSIÓN CORREGIDA
-- =====================================================

CREATE DATABASE biblioteca_sistema 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE biblioteca_sistema;

-- =====================================================
-- TABLA: Ejemplares
-- Gestiona los ejemplares físicos disponibles
-- =====================================================
CREATE TABLE Ejemplares (
    Referencia VARCHAR(50) PRIMARY KEY COMMENT 'Código único del ejemplar',
    Autores VARCHAR(500) NOT NULL COMMENT 'Autores del ejemplar',
    Titulo VARCHAR(300) NOT NULL COMMENT 'Título de la obra',
    Categoria VARCHAR(100) NOT NULL COMMENT 'Categoría temática',
    Num_Paginas BIGINT UNSIGNED NOT NULL COMMENT 'Número de páginas',
    Cantidad_Ejemplares BIGINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Cantidad disponible',
    Fec_registro DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Fecha de registro',
    
    INDEX idx_titulo (Titulo(100)),
    INDEX idx_categoria (Categoria),
    INDEX idx_autores (Autores(100)),
    INDEX idx_fecha (Fec_registro)
) ENGINE=InnoDB COMMENT='Catálogo de ejemplares de la biblioteca';

-- =====================================================
-- TABLA: Estado
-- Catálogo de estados de ubicación
-- =====================================================
CREATE TABLE Estado (
    Cod_Biblioteca VARCHAR(20) PRIMARY KEY COMMENT 'Código de biblioteca/ubicación',
    Ubicacion VARCHAR(200) NOT NULL COMMENT 'Ubicación física específica',
    Img_Ubicacion BIGINT UNSIGNED COMMENT 'Imagen de referencia',
    
    INDEX idx_ubicacion (Ubicacion(50))
) ENGINE=InnoDB COMMENT='Estados y ubicaciones específicas de los ejemplares';

-- =====================================================
-- TABLA: Biblioteca
-- Información detallada de bibliotecas
-- =====================================================
CREATE TABLE Biblioteca (
    Codigo VARCHAR(20) PRIMARY KEY COMMENT 'Código único de biblioteca',
    Nombre VARCHAR(200) NOT NULL COMMENT 'Nombre de la biblioteca',
    Direccion VARCHAR(300) NOT NULL COMMENT 'Dirección física de la biblioteca',
    Encargado VARCHAR(200) NOT NULL COMMENT 'Responsable de la biblioteca',
    Contacto BIGINT UNSIGNED NOT NULL COMMENT 'Teléfono de contacto',
    Correo VARCHAR(150) NOT NULL COMMENT 'Email de contacto',
    
    UNIQUE KEY uk_correo (Correo),
    INDEX idx_nombre (Nombre(50)),
    INDEX idx_encargado (Encargado(50))
) ENGINE=InnoDB COMMENT='Información de las bibliotecas del sistema';

-- =====================================================
-- TABLA: Estado_Libro
-- Relación entre ejemplares, bibliotecas y estados
-- =====================================================
CREATE TABLE Estado_Libro (
    Codigo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'ID único del registro',
    Referencia_Ejemplar VARCHAR(50) NOT NULL COMMENT 'Referencia al ejemplar',
    Cod_Biblioteca VARCHAR(20) NOT NULL COMMENT 'Código de biblioteca',
    Nombre VARCHAR(200) NOT NULL COMMENT 'Nombre descriptivo del estado',
    Nomenclatura VARCHAR(100) COMMENT 'Nomenclatura interna',
    
    FOREIGN KEY (Referencia_Ejemplar) 
        REFERENCES Ejemplares(Referencia) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    FOREIGN KEY (Cod_Biblioteca) 
        REFERENCES Estado(Cod_Biblioteca) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    INDEX idx_referencia (Referencia_Ejemplar),
    INDEX idx_biblioteca (Cod_Biblioteca),
    INDEX idx_nombre (Nombre(50))
) ENGINE=InnoDB COMMENT='Estado actual de los libros por biblioteca';

-- =====================================================
-- TABLA: Historial
-- Registro de movimientos y transacciones
-- =====================================================
CREATE TABLE Historial (
    Item BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT 'ID del registro histórico',
    Referencia_Ejemplar VARCHAR(50) NOT NULL COMMENT 'Referencia al ejemplar',
    Fecha DATE NOT NULL DEFAULT (CURRENT_DATE) COMMENT 'Fecha del movimiento',
    Hora TIME NOT NULL DEFAULT (CURRENT_TIME) COMMENT 'Hora del movimiento',
    
    FOREIGN KEY (Referencia_Ejemplar) 
        REFERENCES Ejemplares(Referencia) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    INDEX idx_fecha_hora (Fecha, Hora),
    INDEX idx_referencia_fecha (Referencia_Ejemplar, Fecha)
) ENGINE=InnoDB COMMENT='Historial de movimientos de ejemplares';

-- =====================================================
-- VISTAS PARA CONSULTAS OPTIMIZADAS
-- =====================================================

-- Vista: Ejemplares disponibles por biblioteca (CORREGIDA)
CREATE VIEW v_disponibilidad_bibliotecas AS
SELECT 
    e.Referencia,
    e.Titulo,
    e.Autores,
    e.Categoria,
    b.Nombre AS Biblioteca,
    b.Direccion AS Direccion_Biblioteca,
    est.Ubicacion AS Ubicacion_Estado,
    e.Cantidad_Ejemplares AS Cantidad_Total,
    COUNT(el.Codigo) AS Ejemplares_Asignados
FROM Ejemplares e
LEFT JOIN Estado_Libro el ON e.Referencia = el.Referencia_Ejemplar
LEFT JOIN Estado est ON el.Cod_Biblioteca = est.Cod_Biblioteca
LEFT JOIN Biblioteca b ON est.Cod_Biblioteca = b.Codigo
GROUP BY e.Referencia, e.Titulo, e.Autores, e.Categoria, 
         b.Nombre, b.Direccion, est.Ubicacion, e.Cantidad_Ejemplares;

-- Vista: Movimientos recientes
CREATE VIEW v_movimientos_recientes AS
SELECT 
    h.Item,
    h.Fecha,
    h.Hora,
    e.Referencia,
    e.Titulo,
    e.Autores,
    e.Categoria
FROM Historial h
INNER JOIN Ejemplares e ON h.Referencia_Ejemplar = e.Referencia
ORDER BY h.Fecha DESC, h.Hora DESC;

-- Vista: Resumen por categoría
CREATE VIEW v_resumen_categorias AS
SELECT 
    e.Categoria,
    COUNT(DISTINCT e.Referencia) AS Total_Titulos,
    SUM(e.Cantidad_Ejemplares) AS Total_Ejemplares,
    COUNT(DISTINCT el.Cod_Biblioteca) AS Bibliotecas_Distribucion
FROM Ejemplares e
LEFT JOIN Estado_Libro el ON e.Referencia = el.Referencia_Ejemplar
GROUP BY e.Categoria;

-- Vista: Inventario completo por biblioteca
CREATE VIEW v_inventario_completo AS
SELECT 
    b.Codigo AS Cod_Biblioteca,
    b.Nombre AS Biblioteca,
    b.Direccion,
    b.Encargado,
    est.Ubicacion,
    e.Referencia,
    e.Titulo,
    e.Autores,
    e.Categoria,
    el.Nomenclatura,
    el.Nombre AS Estado_Actual
FROM Biblioteca b
INNER JOIN Estado est ON b.Codigo = est.Cod_Biblioteca
INNER JOIN Estado_Libro el ON est.Cod_Biblioteca = el.Cod_Biblioteca
INNER JOIN Ejemplares e ON el.Referencia_Ejemplar = e.Referencia
ORDER BY b.Nombre, e.Categoria, e.Titulo;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS
-- =====================================================

DELIMITER $$

-- Procedimiento: Registrar nuevo ejemplar
CREATE PROCEDURE sp_registrar_ejemplar(
    IN p_referencia VARCHAR(50),
    IN p_autores VARCHAR(500),
    IN p_titulo VARCHAR(300),
    IN p_categoria VARCHAR(100),
    IN p_num_paginas BIGINT,
    IN p_cantidad BIGINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error al registrar el ejemplar' AS Mensaje;
    END;
    
    START TRANSACTION;
    
    INSERT INTO Ejemplares (
        Referencia, Autores, Titulo, Categoria, 
        Num_Paginas, Cantidad_Ejemplares
    ) VALUES (
        p_referencia, p_autores, p_titulo, p_categoria,
        p_num_paginas, p_cantidad
    );
    
    COMMIT;
    SELECT 'Ejemplar registrado exitosamente' AS Mensaje, p_referencia AS Referencia;
END$$

-- Procedimiento: Registrar movimiento en historial
CREATE PROCEDURE sp_registrar_movimiento(
    IN p_referencia VARCHAR(50)
)
BEGIN
    DECLARE v_existe INT;
    
    -- Verificar si el ejemplar existe
    SELECT COUNT(*) INTO v_existe 
    FROM Ejemplares 
    WHERE Referencia = p_referencia;
    
    IF v_existe > 0 THEN
        INSERT INTO Historial (Referencia_Ejemplar)
        VALUES (p_referencia);
        
        SELECT 'Movimiento registrado exitosamente' AS Mensaje;
    ELSE
        SELECT 'Error: Ejemplar no existe' AS Mensaje;
    END IF;
END$$

-- Procedimiento: Buscar ejemplares
CREATE PROCEDURE sp_buscar_ejemplares(
    IN p_criterio VARCHAR(300)
)
BEGIN
    SELECT 
        Referencia,
        Titulo,
        Autores,
        Categoria,
        Num_Paginas,
        Cantidad_Ejemplares,
        Fec_registro
    FROM Ejemplares
    WHERE Titulo LIKE CONCAT('%', p_criterio, '%')
       OR Autores LIKE CONCAT('%', p_criterio, '%')
       OR Categoria LIKE CONCAT('%', p_criterio, '%')
       OR Referencia LIKE CONCAT('%', p_criterio, '%')
    ORDER BY Titulo;
END$$

-- Procedimiento: Obtener historial de ejemplar
CREATE PROCEDURE sp_historial_ejemplar(
    IN p_referencia VARCHAR(50),
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE
)
BEGIN
    SELECT 
        h.Item,
        h.Fecha,
        h.Hora,
        e.Titulo,
        e.Autores,
        e.Categoria
    FROM Historial h
    INNER JOIN Ejemplares e ON h.Referencia_Ejemplar = e.Referencia
    WHERE h.Referencia_Ejemplar = p_referencia
      AND h.Fecha BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY h.Fecha DESC, h.Hora DESC;
END$$

-- Procedimiento: Asignar ejemplar a biblioteca
CREATE PROCEDURE sp_asignar_ejemplar_biblioteca(
    IN p_referencia VARCHAR(50),
    IN p_cod_biblioteca VARCHAR(20),
    IN p_nombre_estado VARCHAR(200),
    IN p_nomenclatura VARCHAR(100)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error al asignar ejemplar a biblioteca' AS Mensaje;
    END;
    
    START TRANSACTION;
    
    INSERT INTO Estado_Libro (
        Referencia_Ejemplar,
        Cod_Biblioteca,
        Nombre,
        Nomenclatura
    ) VALUES (
        p_referencia,
        p_cod_biblioteca,
        p_nombre_estado,
        p_nomenclatura
    );
    
    -- Registrar en historial
    INSERT INTO Historial (Referencia_Ejemplar)
    VALUES (p_referencia);
    
    COMMIT;
    SELECT 'Ejemplar asignado exitosamente' AS Mensaje;
END$$

-- Procedimiento: Obtener estadísticas generales
CREATE PROCEDURE sp_estadisticas_generales()
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM Ejemplares) AS Total_Ejemplares,
        (SELECT SUM(Cantidad_Ejemplares) FROM Ejemplares) AS Total_Unidades,
        (SELECT COUNT(*) FROM Biblioteca) AS Total_Bibliotecas,
        (SELECT COUNT(*) FROM Historial) AS Total_Movimientos,
        (SELECT COUNT(DISTINCT Categoria) FROM Ejemplares) AS Total_Categorias;
END$$

DELIMITER ;

-- =====================================================
-- DATOS DE EJEMPLO
-- =====================================================

-- Insertar estados/ubicaciones
INSERT INTO Estado (Cod_Biblioteca, Ubicacion, Img_Ubicacion) VALUES
('BIB001', 'Biblioteca Central - Planta Baja - Estantería A', 1),
('BIB002', 'Biblioteca Norte - Segundo Piso - Sala Lectura', 2),
('BIB003', 'Biblioteca Sur - Sala de Consulta - Estantería B', 3),
('BIB004', 'Biblioteca Central - Primer Piso - Área Técnica', 4),
('BIB005', 'Biblioteca Norte - Planta Baja - Recepción', 5);

-- Insertar bibliotecas
INSERT INTO Biblioteca (Codigo, Nombre, Direccion, Encargado, Contacto, Correo) VALUES
('BIB001', 'Biblioteca Central', 'Av. Principal 123, Ciudad Central', 'María González Pérez', 5551234567, 'central@biblioteca.com'),
('BIB002', 'Biblioteca Norte', 'Calle Norte 456, Sector Industrial', 'Juan Pérez Martínez', 5557654321, 'norte@biblioteca.com'),
('BIB003', 'Biblioteca Sur', 'Av. Sur 789, Zona Residencial', 'Ana Martínez López', 5559876543, 'sur@biblioteca.com');

-- Insertar ejemplares de muestra
INSERT INTO Ejemplares (Referencia, Autores, Titulo, Categoria, Num_Paginas, Cantidad_Ejemplares) VALUES
('LIT-001', 'Gabriel García Márquez', 'Cien Años de Soledad', 'Literatura', 471, 15),
('LIT-002', 'Isabel Allende', 'La Casa de los Espíritus', 'Literatura', 433, 10),
('LIT-003', 'Mario Vargas Llosa', 'La Ciudad y los Perros', 'Literatura', 408, 8),
('LIT-004', 'Jorge Luis Borges', 'Ficciones', 'Literatura', 174, 12),
('TEC-001', 'Donald Knuth', 'The Art of Computer Programming Vol. 1', 'Tecnología', 672, 5),
('TEC-002', 'Robert C. Martin', 'Clean Code', 'Tecnología', 464, 20),
('TEC-003', 'Thomas H. Cormen', 'Introduction to Algorithms', 'Tecnología', 1312, 7),
('CIE-001', 'Stephen Hawking', 'Breve Historia del Tiempo', 'Ciencia', 256, 12),
('CIE-002', 'Carl Sagan', 'Cosmos', 'Ciencia', 365, 9),
('CIE-003', 'Richard Dawkins', 'El Gen Egoísta', 'Ciencia', 360, 6),
('HIS-001', 'Yuval Noah Harari', 'Sapiens: De Animales a Dioses', 'Historia', 498, 18),
('HIS-002', 'Jared Diamond', 'Armas, Gérmenes y Acero', 'Historia', 530, 8),
('FIL-001', 'Friedrich Nietzsche', 'Así Habló Zaratustra', 'Filosofía', 352, 5),
('FIL-002', 'Platón', 'La República', 'Filosofía', 416, 10),
('MAT-001', 'Ian Stewart', 'Historia de las Matemáticas', 'Matemáticas', 624, 7);

-- Insertar estados de libros
INSERT INTO Estado_Libro (Referencia_Ejemplar, Cod_Biblioteca, Nombre, Nomenclatura) VALUES
('LIT-001', 'BIB001', 'Disponible', 'CENT-LIT-001-A'),
('LIT-002', 'BIB002', 'Disponible', 'NORT-LIT-002-B'),
('LIT-003', 'BIB003', 'Disponible', 'SUR-LIT-003-C'),
('LIT-004', 'BIB001', 'Disponible', 'CENT-LIT-004-A'),
('TEC-001', 'BIB001', 'Disponible', 'CENT-TEC-001-A'),
('TEC-002', 'BIB002', 'Disponible', 'NORT-TEC-002-B'),
('TEC-003', 'BIB001', 'En Préstamo', 'CENT-TEC-003-A'),
('CIE-001', 'BIB002', 'Disponible', 'NORT-CIE-001-B'),
('CIE-002', 'BIB003', 'Disponible', 'SUR-CIE-002-C'),
('CIE-003', 'BIB001', 'Disponible', 'CENT-CIE-003-A'),
('HIS-001', 'BIB002', 'Disponible', 'NORT-HIS-001-B'),
('HIS-002', 'BIB003', 'En Restauración', 'SUR-HIS-002-C'),
('FIL-001', 'BIB001', 'Disponible', 'CENT-FIL-001-A'),
('FIL-002', 'BIB002', 'Disponible', 'NORT-FIL-002-B'),
('MAT-001', 'BIB003', 'Disponible', 'SUR-MAT-001-C');

-- Insertar algunos movimientos en el historial
INSERT INTO Historial (Referencia_Ejemplar, Fecha, Hora) VALUES
('LIT-001', '2025-09-01', '09:30:00'),
('TEC-002', '2025-09-05', '14:15:00'),
('CIE-001', '2025-09-10', '11:45:00'),
('HIS-001', '2025-09-15', '16:20:00'),
('LIT-003', '2025-09-20', '10:00:00'),
('TEC-003', '2025-09-25', '13:30:00'),
('FIL-001', '2025-09-28', '15:45:00');

-- =====================================================
-- CONSULTAS DE VERIFICACIÓN Y PRUEBA
-- =====================================================

-- Ver disponibilidad por biblioteca
SELECT '=== DISPONIBILIDAD POR BIBLIOTECA ===' AS Seccion;
SELECT * FROM v_disponibilidad_bibliotecas;

-- Ver resumen por categoría
SELECT '=== RESUMEN POR CATEGORÍA ===' AS Seccion;
SELECT * FROM v_resumen_categorias;

-- Ver inventario completo
SELECT '=== INVENTARIO COMPLETO ===' AS Seccion;
SELECT * FROM v_inventario_completo LIMIT 10;

-- Ver movimientos recientes
SELECT '=== MOVIMIENTOS RECIENTES ===' AS Seccion;
SELECT * FROM v_movimientos_recientes LIMIT 10;

-- Estadísticas generales
SELECT '=== ESTADÍSTICAS GENERALES ===' AS Seccion;
CALL sp_estadisticas_generales();

-- =====================================================
-- INFORMACIÓN DEL SISTEMA
-- =====================================================

SELECT 
    'Base de datos creada exitosamente' AS Estado,
    DATABASE() AS Base_Datos,
    VERSION() AS Version_MySQL,
    NOW() AS Fecha_Hora_Creacion,
    'Todas las correcciones aplicadas' AS Nota;
    
   SELECT 
    Titulo,
    Biblioteca,
    Direccion_Biblioteca,
    Ubicacion_Estado,
    Cantidad_Total,
    Ejemplares_Asignados
FROM v_disponibilidad_bibliotecas
WHERE Biblioteca IS NOT NULL
ORDER BY Biblioteca, Titulo;