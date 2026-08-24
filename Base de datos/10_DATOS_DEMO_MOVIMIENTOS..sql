--------------------------------------------------------------------------------
-- 10_DATOS_DEMO_MOVIMIENTOS.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Historial de movimientos de ejemplo, referenciando los repuestos de
-- 09_DATOS_DEMO_REPUESTOS.sql por CODIGO (no por ID fijo).
--
-- IMPORTANTE: a diferencia de la página "Registrar Movimiento" (que llama
-- a PKG_INVENTARIO y por lo tanto SÍ actualiza el stock), estos INSERT son
-- directos a la tabla, a propósito, para no alterar los niveles de
-- STOCK_ACTUAL que ya quedaron armados en el script de repuestos (algunos
-- por debajo del mínimo, para la demo del badge). Es solo historial visual.
--------------------------------------------------------------------------------

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0001'), 'ENTRADA', 50, 'Compra a proveedor - reposición trimestral', SYSDATE - 25, 'admin');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0001'), 'SALIDA', 5, 'Instalación de puestos nuevos - Planta 2', SYSDATE - 12, 'jgarcia');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0002'), 'ENTRADA', 6, 'Compra a proveedor', SYSDATE - 20, 'admin');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0002'), 'SALIDA', 3, 'Ampliación de memoria - PC-RRHH-05', SYSDATE - 6, 'mlopez');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0003'), 'ENTRADA', 10, 'Compra a proveedor', SYSDATE - 18, 'admin');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0003'), 'SALIDA', 2, 'Reemplazo de disco - SRV-DB-01', SYSDATE - 3, 'jgarcia');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0004'), 'ENTRADA', 5, 'Compra a proveedor', SYSDATE - 30, 'admin');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0004'), 'SALIDA', 3, 'Cambio de tóner - IMP-PLANTA1-02', SYSDATE - 9, 'mlopez');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0006'), 'ENTRADA', 20, 'Compra a proveedor', SYSDATE - 15, 'admin');

INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, FECHA, USUARIO)
VALUES ((SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0007'), 'SALIDA', 3, 'Ampliación de switch - SW-CORE-02', SYSDATE - 4, 'jgarcia');

COMMIT;

-- Verificación
SELECT r.codigo, r.nombre, m.tipo_movimiento, m.cantidad, m.fecha, m.usuario
  FROM OP_MOVIMIENTOS_STOCK m
  JOIN OP_REPUESTOS r ON r.id_repuesto = m.id_repuesto
 ORDER BY m.fecha DESC;