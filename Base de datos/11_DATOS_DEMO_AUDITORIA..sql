--------------------------------------------------------------------------------
-- 11_DATOS_DEMO_AUDITORIA.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Registros de ejemplo para OP_AUDITORIA. Referencia registros reales por
-- CODIGO/USERNAME donde puede (repuestos, técnicos), así que funciona sin
-- importar qué hayas cargado ya a mano.
--------------------------------------------------------------------------------

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_TECNICOS', (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'admin'), 'INSERT', 'admin', SYSDATE - 20, 'Técnico creado: Administrador CMMS');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_TECNICOS', (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia'), 'INSERT', 'admin', SYSDATE - 19, 'Técnico creado: Juan García');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_ACTIVOS', (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01'), 'INSERT', 'admin', SYSDATE - 17, 'Equipo dado de alta: SRV-DB-01');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_ACTIVOS', (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'LAP-VENTAS-12'), 'UPDATE', 'jgarcia', SYSDATE - 10, 'Estado cambiado a EN_REPARACION');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_REPUESTOS', (SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0001'), 'INSERT', 'admin', SYSDATE - 25, 'Repuesto creado: Cable de red Cat6');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_REPUESTOS', (SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0002'), 'UPDATE', 'admin', SYSDATE - 20, 'Stock actualizado: +6 (Entrada)');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_REPUESTOS', (SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0002'), 'UPDATE', 'mlopez', SYSDATE - 6, 'Stock actualizado: -3 (Salida)');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_REPUESTOS', (SELECT id_repuesto FROM OP_REPUESTOS WHERE codigo = 'REP-0007'), 'UPDATE', 'jgarcia', SYSDATE - 4, 'Stock actualizado: -3 (Salida) - por debajo del mínimo');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_PROVEEDORES', (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Dell Technologies'), 'INSERT', 'admin', SYSDATE - 30, 'Proveedor creado: Dell Technologies');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_TECNICOS', (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'mlopez'), 'UPDATE', 'admin', SYSDATE - 2, 'Especialidad actualizada a Soporte de Hardware');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_ACTIVOS', (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-ANTIGUO-01'), 'UPDATE', 'admin', SYSDATE - 1, 'Estado cambiado a ALMACEN - equipo retirado de uso');

INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, FECHA_EVENTO, DETALLE)
VALUES ('OP_UBICACIONES', NULL, 'DELETE', 'admin', SYSDATE - 15, 'Ubicación eliminada: Almacén Antiguo (sin activos asociados)');

COMMIT;

-- Verificación
SELECT nombre_tabla, accion, usuario, fecha_evento, detalle
  FROM OP_AUDITORIA
 ORDER BY fecha_evento DESC;