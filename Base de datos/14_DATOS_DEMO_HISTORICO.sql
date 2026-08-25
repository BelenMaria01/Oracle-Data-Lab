--------------------------------------------------------------------------------
-- 14_DATOS_DEMO_HISTORICO.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere 07_DATOS_DEMO.sql (activos/técnicos) y
-- 12_DATOS_DEMO_ORDENES.sql ya ejecutados.
--
-- 6 Órdenes de Trabajo adicionales, con fechas repartidas en 2024 y 2025
-- (no solo agosto 2026 como el resto de la demo), todas con coste de mano
-- de obra cargado, para poder probar Home (gráfico "últimos 6 meses" /
-- Coste de Mantenimiento) e Informe de Costes con un histórico más largo
-- y confirmar que las agregaciones por fecha no se rompen con datos viejos.
--
-- Todas se crean directamente RESUELTAS o CERRADAS (ya son historial),
-- así que se insertan en un solo paso y después se fuerza FECHA_CREACION/
-- FECHA_FIN hacia atrás — no tiene sentido simular el ciclo de vida
-- completo de un ticket que "ya pasó".
--------------------------------------------------------------------------------

DECLARE
    v_id_orden   NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01';
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Mantenimiento preventivo anual de servidores',
        p_descripcion    => 'Revisión anual programada: limpieza de polvo, verificación de ventiladores y actualización de firmware.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'PREVENTIVO',
        p_prioridad      => 'MEDIA',
        p_id_solicitante => 'admin'
    );

    PKG_ORDENES.asignar_tecnico(v_id_orden, v_id_tecnico, 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MENOR',
           FECHA_CREACION = DATE '2024-02-10',
           FECHA_FIN = DATE '2024-02-11',
           COSTE_MANO_OBRA = 85.00
     WHERE ID_ORDEN = v_id_orden;
END;
/

DECLARE
    v_id_orden   NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-RRHH-05';
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'mlopez';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Sustitución de disco duro por fallo SMART',
        p_descripcion    => 'El equipo reportaba errores SMART recurrentes. Se sustituyó el disco por uno nuevo.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'ALTA',
        p_id_solicitante => 'admin'
    );

    PKG_ORDENES.asignar_tecnico(v_id_orden, v_id_tecnico, 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'mlopez');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'mlopez');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MAYOR',
           FECHA_CREACION = DATE '2024-07-22',
           FECHA_FIN = DATE '2024-07-23',
           COSTE_MANO_OBRA = 120.00
     WHERE ID_ORDEN = v_id_orden;
END;
/

DECLARE
    v_id_orden   NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'SW-CORE-02';
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Actualización de firmware del switch core',
        p_descripcion    => 'Actualización programada de firmware para corregir vulnerabilidad reportada por el fabricante.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'PREVENTIVO',
        p_prioridad      => 'MEDIA',
        p_id_solicitante => 'admin'
    );

    PKG_ORDENES.asignar_tecnico(v_id_orden, v_id_tecnico, 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MENOR',
           FECHA_CREACION = DATE '2025-01-15',
           FECHA_FIN = DATE '2025-01-15',
           COSTE_MANO_OBRA = 45.00
     WHERE ID_ORDEN = v_id_orden;
END;
/

DECLARE
    v_id_orden   NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'IMP-PLANTA1-02';
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'mlopez';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Cambio de fusor de impresora',
        p_descripcion    => 'El fusor llegó al final de su vida útil, se reemplazó por uno nuevo.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'admin'
    );

    PKG_ORDENES.asignar_tecnico(v_id_orden, v_id_tecnico, 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'mlopez');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'mlopez');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'MENOR',
           FECHA_CREACION = DATE '2025-05-30',
           FECHA_FIN = DATE '2025-05-31',
           COSTE_MANO_OBRA = 60.00
     WHERE ID_ORDEN = v_id_orden;
END;
/

DECLARE
    v_id_orden   NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'LAP-VENTAS-12';
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Sustitución de batería de portátil',
        p_descripcion    => 'La batería ya no retenía carga. Se sustituyó por una nueva original del fabricante.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'admin'
    );

    PKG_ORDENES.asignar_tecnico(v_id_orden, v_id_tecnico, 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'jgarcia');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'TRIVIAL',
           FECHA_CREACION = DATE '2026-01-20',
           FECHA_FIN = DATE '2026-01-20',
           COSTE_MANO_OBRA = 30.00
     WHERE ID_ORDEN = v_id_orden;
END;
/

DECLARE
    v_id_orden   NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-ANTIGUO-01';
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'admin';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Limpieza y mantenimiento preventivo trimestral',
        p_descripcion    => 'Mantenimiento preventivo trimestral estándar de equipos de almacén.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'PREVENTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'admin'
    );

    PKG_ORDENES.asignar_tecnico(v_id_orden, v_id_tecnico, 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'EN_PROCESO', 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'RESUELTO', 'admin');
    PKG_ORDENES.cambiar_estado(v_id_orden, 'CERRADO', 'admin');

    UPDATE OP_ORDENES_TRABAJO
       SET SEVERIDAD = 'TRIVIAL',
           FECHA_CREACION = DATE '2026-04-05',
           FECHA_FIN = DATE '2026-04-05',
           COSTE_MANO_OBRA = 20.00
     WHERE ID_ORDEN = v_id_orden;
END;
/

COMMIT;

SELECT TO_CHAR(fecha_creacion,'YYYY-MM') mes, COUNT(*) cantidad, SUM(coste_mano_obra) coste
  FROM OP_ORDENES_TRABAJO
 WHERE fecha_creacion < DATE '2026-08-01'
 GROUP BY TO_CHAR(fecha_creacion,'YYYY-MM')
 ORDER BY mes;
