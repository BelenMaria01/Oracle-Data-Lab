--------------------------------------------------------------------------------
-- 12_DATOS_DEMO_ORDENES.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere que 07_DATOS_DEMO.sql ya se haya
-- ejecutado (usa los 6 activos y 3 técnicos de ejemplo por NOMBRE/USERNAME).
--
-- 8 Órdenes de Trabajo de ejemplo, cubriendo los 6 estados posibles:
--   NUEVO (x2, sin técnico asignado = "pendiente de asignación")
--   EN_PROCESO (x2, activo, con técnico)
--   RESUELTO (x1)
--   CERRADO (x1)
--   REABIERTO (x1)
--   CANCELADO (x1)
--
-- Usa siempre PKG_ORDENES (crear_orden / asignar_tecnico / cambiar_estado),
-- nunca INSERT directo, para que quede registrado también en
-- OP_ORDEN_HISTORIAL y OP_AUDITORIA, igual que si se hubiera hecho desde
-- la app. NO es idempotente: cada corrida crea 8 órdenes nuevas.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. NUEVO — pendiente de asignación, crítica (sin técnico)
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'El servidor no enciende - sin POST',
        p_descripcion    => 'Esta mañana el servidor de base de datos no arrancó. Ni luces ni beep de POST.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01'),
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'CRITICA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'CRITICA',
           PASOS_REPRODUCCION = 'Presionar el botón de encendido. No hay respuesta ni en el panel frontal ni por iDRAC.',
           FECHA_CREACION = SYSDATE - 1
     WHERE ID_ORDEN = v_id_orden;
END;
/

--------------------------------------------------------------------------------
-- 2. NUEVO — pendiente de asignación, preventivo de rutina (sin técnico)
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Actualizar antivirus y parches de Windows',
        p_descripcion    => 'Mantenimiento preventivo trimestral: actualizar firmas de antivirus y aplicar parches pendientes.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-RRHH-05'),
        p_tipo           => 'PREVENTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'TRIVIAL',
           FECHA_CREACION = SYSDATE - 2
     WHERE ID_ORDEN = v_id_orden;
END;
/

--------------------------------------------------------------------------------
-- 3. EN_PROCESO — activo, asignado a jgarcia
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Ping intermitente en switch core',
        p_descripcion    => 'Se reportan cortes intermitentes de red en Planta 2. El switch principal responde a ping de forma irregular.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'SW-CORE-02'),
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'ALTA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MAYOR',
           PASOS_REPRODUCCION = 'Hacer ping continuo al switch (10.0.1.1) durante 5 minutos. Se pierden paquetes cada 30-40 segundos aprox.',
           FECHA_CREACION = SYSDATE - 3
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia'),
        p_usuario    => 'admin'
    );

    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'jgarcia');
END;
/

--------------------------------------------------------------------------------
-- 4. EN_PROCESO — activo, asignado a jgarcia (portátil ya en EN_REPARACION)
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Pantalla rota tras caída',
        p_descripcion    => 'El portátil se cayó de la mesa. La pantalla quedó con una fractura visible y zonas negras.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'LAP-VENTAS-12'),
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'MEDIA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MAYOR',
           FECHA_CREACION = SYSDATE - 4
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia'),
        p_usuario    => 'admin'
    );

    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'jgarcia');
END;
/

--------------------------------------------------------------------------------
-- 5. RESUELTO — pendiente de que el solicitante confirme y se cierre
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Atasco de papel recurrente',
        p_descripcion    => 'La impresora atasca papel en bandeja 2 varias veces al día.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'IMP-PLANTA1-02'),
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MENOR',
           FECHA_CREACION = SYSDATE - 6,
           COSTE_MANO_OBRA = 25.00
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'mlopez'),
        p_usuario    => 'admin'
    );

    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'mlopez');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'mlopez');
END;
/

--------------------------------------------------------------------------------
-- 6. CERRADO — ciclo completo terminado
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Puesta a punto antes de reasignar equipo',
        p_descripcion    => 'Formatear, reinstalar SO y dejar listo el equipo de almacén para un nuevo empleado.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-ANTIGUO-01'),
        p_tipo           => 'PREVENTIVO',
        p_prioridad      => 'MEDIA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'TRIVIAL',
           FECHA_CREACION = SYSDATE - 10,
           COSTE_MANO_OBRA = 40.00
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'admin'),
        p_usuario    => 'admin'
    );

    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');
END;
/

--------------------------------------------------------------------------------
-- 7. REABIERTO — se había dado por resuelto pero el problema volvió
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Fallo de disco intermitente',
        p_descripcion    => 'El servidor reporta errores SMART en uno de los discos del RAID de forma esporádica.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01'),
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'ALTA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MAYOR',
           FECHA_CREACION = SYSDATE - 15,
           COSTE_MANO_OBRA = 60.00
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia'),
        p_usuario    => 'admin'
    );

    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'REABIERTO', 'admin');
END;
/

--------------------------------------------------------------------------------
-- 8. CANCELADO — reportada por error / duplicada
--------------------------------------------------------------------------------
DECLARE
    v_id_orden NUMBER;
BEGIN
    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Solicitud duplicada de repuesto',
        p_descripcion    => 'Ticket creado por error, ya existe otra orden abierta para el mismo problema.',
        p_id_activo      => (SELECT id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-RRHH-05'),
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'admin'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'TRIVIAL',
           FECHA_CREACION = SYSDATE - 5
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.cambiar_estado(v_id_orden, 'CANCELADO', 'admin');
END;
/

COMMIT;

--------------------------------------------------------------------------------
-- 9. Verificación — debería mostrar 8 filas nuevas, una por estado excepto
--    NUEVO (2) y EN_PROCESO (2)
--------------------------------------------------------------------------------

SELECT estado, COUNT(*) cantidad
  FROM OP_ORDENES_TRABAJO
 GROUP BY estado
 ORDER BY estado;

SELECT id_orden, titulo, estado, prioridad, severidad, id_tecnico_asignado
  FROM OP_ORDENES_TRABAJO
 ORDER BY id_orden DESC
 FETCH FIRST 8 ROWS ONLY;
