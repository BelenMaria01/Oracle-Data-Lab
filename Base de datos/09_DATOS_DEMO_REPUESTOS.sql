--------------------------------------------------------------------------------
-- 09_DATOS_DEMO_REPUESTOS.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Repuestos de ejemplo. Usa subconsultas por NOMBRE de proveedor (no IDs
-- fijos), así que funciona sin importar qué hayas cargado ya a mano.
-- Incluye a propósito repuestos con STOCK_ACTUAL por debajo de
-- STOCK_MINIMO, para ver la alerta funcionando en Home e Inventario.
--------------------------------------------------------------------------------

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0001', 'Cable de red Cat6', 'Cable UTP categoría 6, 1 metro', 'Redes', 45, 20, 'UD', 1.20,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Cisco Systems España'), 'Estantería A-1');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0002', 'Módulo RAM DDR4 8GB', 'Memoria RAM DDR4 2666MHz 8GB', 'Componentes', 3, 5, 'UD', 28.50,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Dell Technologies'), 'Estantería B-2');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0003', 'SSD SATA 480GB', 'Disco de estado sólido 480GB SATA III', 'Almacenamiento', 8, 4, 'UD', 42.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'HP Enterprise'), 'Estantería B-3');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0004', 'Tóner LaserJet negro', 'Cartucho de tóner negro compatible M507', 'Consumibles', 2, 3, 'UD', 65.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'HP Enterprise'), 'Estantería C-1');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0005', 'Fuente de alimentación 650W', 'PSU ATX 650W 80+ Bronze', 'Componentes', 6, 2, 'UD', 55.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Dell Technologies'), 'Estantería B-1');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0006', 'Teclado USB estándar', 'Teclado con cable, distribución español', 'Periféricos', 15, 5, 'UD', 9.90,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Tecnología Ibérica S.L.'), 'Estantería C-2');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0007', 'Transceptor SFP 1G', 'Módulo SFP 1000BASE-T para switches', 'Redes', 1, 4, 'UD', 18.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Cisco Systems España'), 'Estantería A-2');

INSERT INTO OP_REPUESTOS (CODIGO, NOMBRE, DESCRIPCION, CATEGORIA, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD_MEDIDA, COSTE_UNITARIO, ID_PROVEEDOR, UBICACION_ALMACEN)
VALUES ('REP-0008', 'Batería CMOS CR2032', 'Pila de botón para placas base', 'Componentes', 25, 10, 'UD', 0.80,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Tecnología Ibérica S.L.'), 'Estantería D-1');

COMMIT;

-- Verificación
SELECT codigo, nombre, categoria, stock_actual, stock_minimo,
       CASE WHEN stock_actual < stock_minimo THEN 'BAJO MÍNIMO' ELSE 'OK' END AS estado_stock
  FROM OP_REPUESTOS
 ORDER BY nombre;