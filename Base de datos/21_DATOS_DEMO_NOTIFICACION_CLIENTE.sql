--------------------------------------------------------------------------------
-- 21_DATOS_DEMO_NOTIFICACION_CLIENTE.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere que ya se hayan corrido:
--   17_DATOS_DEMO_TICKETS_CLIENTE_DEMO.sql, 20_NOTIFICACIONES_CLIENTE.sql
--
-- No inserta nada directo en OP_NOTIFICACIONES: dispara un cambio de
-- estado real vía PKG_ORDENES.cambiar_estado sobre uno de los tickets
-- demo de cliente_demo ("Lentitud al abrir el sistema de facturación",
-- que estaba en EN_PROCESO), para que el trigger
-- TRG_OP_ORDENES_NOTIF_CLIENTE genere una notificación real y se pueda
-- ver la página nueva funcionando sin tener que esperar a que un
-- técnico cambie un ticket a mano.
--------------------------------------------------------------------------------

DECLARE
    v_id_orden NUMBER;
BEGIN
    SELECT id_orden INTO v_id_orden
      FROM OP_ORDENES_TRABAJO
     WHERE titulo = 'Lentitud al abrir el sistema de facturación';

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'RESUELTO',
        p_usuario      => 'jgarcia'
    );
END;
/

COMMIT;

--------------------------------------------------------------------------------
-- Verificación
--------------------------------------------------------------------------------
SELECT n.id_notificacion, n.mensaje, n.leida, c.usuario_apex
  FROM OP_NOTIFICACIONES n
  JOIN OP_CLIENTES c ON c.id_cliente = n.id_cliente_destino
 WHERE c.usuario_apex = 'cliente_demo'
 ORDER BY n.fecha_creacion DESC;
