--------------------------------------------------------------------------------
-- 03_TRIGGERS.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Ejecutar DESPUÉS de 01_TABLAS.sql y 02_PAQUETES.sql
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. Notificar cuando un repuesto cruza por debajo del stock mínimo
--    (solo notifica en el momento del cruce, no en cada UPDATE posterior,
--    para no generar notificaciones duplicadas)
--------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER TRG_OP_REPUESTOS_NOTIF_STOCK
AFTER UPDATE OF stock_actual ON OP_REPUESTOS
FOR EACH ROW
WHEN (NEW.stock_actual < NEW.stock_minimo)
BEGIN
    IF :OLD.stock_actual >= :OLD.stock_minimo THEN
        PKG_NOTIFICACIONES.generar_notificacion(
            p_tipo               => 'STOCK_BAJO',
            p_mensaje            => 'El repuesto "' || :NEW.nombre || '" está bajo el stock mínimo (' ||
                                     :NEW.stock_actual || '/' || :NEW.stock_minimo || ').',
            p_id_registro        => :NEW.id_repuesto,
            p_nombre_tabla       => 'OP_REPUESTOS',
            p_id_tecnico_destino => NULL
        );
    END IF;
END;
/

--------------------------------------------------------------------------------
-- 2. Notificar al técnico cuando se le asigna una orden de trabajo / ticket
--------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER TRG_OP_ORDENES_NOTIF_ASIGNACION
AFTER INSERT OR UPDATE OF id_tecnico_asignado ON OP_ORDENES_TRABAJO
FOR EACH ROW
WHEN (NEW.id_tecnico_asignado IS NOT NULL)
DECLARE
    v_cambio BOOLEAN := TRUE;
BEGIN
    IF UPDATING AND :OLD.id_tecnico_asignado = :NEW.id_tecnico_asignado THEN
        v_cambio := FALSE;
    END IF;

    IF v_cambio THEN
        PKG_NOTIFICACIONES.generar_notificacion(
            p_tipo               => 'ORDEN_ASIGNADA',
            p_mensaje            => 'Se te ha asignado la orden #' || :NEW.id_orden || ': ' || :NEW.titulo,
            p_id_registro        => :NEW.id_orden,
            p_nombre_tabla       => 'OP_ORDENES_TRABAJO',
            p_id_tecnico_destino => :NEW.id_tecnico_asignado
        );
    END IF;
END;
/

--------------------------------------------------------------------------------
-- 3. Verificación
--------------------------------------------------------------------------------

SELECT object_name, object_type, status
FROM user_objects
WHERE object_type = 'TRIGGER'
ORDER BY object_name;