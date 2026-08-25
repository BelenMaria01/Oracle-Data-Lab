--------------------------------------------------------------------------------
-- 13_DATOS_DEMO_NOTIFICACIONES.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere 07_DATOS_DEMO.sql (técnicos) ya ejecutado.
--
-- 6 notificaciones de ejemplo: 2 de stock bajo (visibles a todo el staff,
-- id_tecnico_destino NULL), 3 asignadas a técnicos concretos, algunas ya
-- marcadas como leídas y con fecha atrasada, para poder probar tanto el
-- listado con badges como el botón "Marcar todas como leídas".
--------------------------------------------------------------------------------

BEGIN
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'STOCK_BAJO',
        p_mensaje            => 'El repuesto "Transceptor SFP 1G" está bajo el stock mínimo (1/4).',
        p_nombre_tabla       => 'OP_REPUESTOS',
        p_id_tecnico_destino => NULL
    );
END;
/

BEGIN
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'STOCK_BAJO',
        p_mensaje            => 'El repuesto "Módulo RAM DDR4 8GB" está bajo el stock mínimo (3/5).',
        p_nombre_tabla       => 'OP_REPUESTOS',
        p_id_tecnico_destino => NULL
    );
END;
/

DECLARE
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia';
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'ORDEN_ASIGNADA',
        p_mensaje            => 'Se te ha asignado la orden: Ping intermitente en switch core',
        p_nombre_tabla       => 'OP_ORDENES_TRABAJO',
        p_id_tecnico_destino => v_id_tecnico
    );
END;
/

DECLARE
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'mlopez';
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'ORDEN_ASIGNADA',
        p_mensaje            => 'Se te ha asignado la orden: Atasco de papel recurrente',
        p_nombre_tabla       => 'OP_ORDENES_TRABAJO',
        p_id_tecnico_destino => v_id_tecnico
    );
    -- Esta la marcamos como ya leída, con fecha de hace 3 días
    UPDATE OP_NOTIFICACIONES
       SET leida = 'S', fecha_creacion = SYSDATE - 3
     WHERE id_tecnico_destino = v_id_tecnico
       AND tipo = 'ORDEN_ASIGNADA'
       AND mensaje LIKE '%Atasco de papel%';
END;
/

DECLARE
    v_id_tecnico NUMBER;
BEGIN
    SELECT id_tecnico INTO v_id_tecnico FROM OP_TECNICOS WHERE username = 'admin';
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'ORDEN_ASIGNADA',
        p_mensaje            => 'Se te ha asignado la orden: Puesta a punto antes de reasignar equipo',
        p_nombre_tabla       => 'OP_ORDENES_TRABAJO',
        p_id_tecnico_destino => v_id_tecnico
    );
END;
/

-- Una más, ya leída y con más de una semana, para que se note el contraste visual
BEGIN
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'STOCK_BAJO',
        p_mensaje            => 'El repuesto "Tóner LaserJet negro" está bajo el stock mínimo (2/3).',
        p_nombre_tabla       => 'OP_REPUESTOS',
        p_id_tecnico_destino => NULL
    );
    UPDATE OP_NOTIFICACIONES
       SET leida = 'S', fecha_creacion = SYSDATE - 9
     WHERE tipo = 'STOCK_BAJO'
       AND mensaje LIKE '%Tóner LaserJet%';
END;
/

COMMIT;

SELECT id_notificacion, tipo, leida, id_tecnico_destino,
       TO_CHAR(fecha_creacion,'DD/MM/YYYY HH24:MI') fecha, mensaje
  FROM OP_NOTIFICACIONES
 ORDER BY fecha_creacion DESC;
