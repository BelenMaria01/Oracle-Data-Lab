--------------------------------------------------------------------------------
-- 18_DATOS_DEMO_SEGUNDO_CLIENTE.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere que ya se hayan corrido:
--   07_DATOS_DEMO.sql, 15_CREAR_USUARIOS_PRUEBA.sql, 17_DATOS_DEMO_TICKETS_CLIENTE_DEMO.sql
--
-- Motivo: "Tickets de Mi Empresa" (página 29) y "Mis Tickets" (página 21)
-- mostraban exactamente lo mismo para cliente_demo — no porque estuvieran
-- mal filtradas nada más, sino porque la ÚNICA empresa demo ("Cliente Demo
-- S.L.") tenía un solo cliente (cliente_demo). Con un solo cliente en la
-- empresa, "todos los tickets de la empresa" y "mis tickets" son
-- necesariamente el mismo conjunto.
--
-- Esta migración agrega un SEGUNDO cliente dentro de la misma empresa
-- ("Cliente Demo S.L."), sin cuenta de login de APEX (no necesita entrar
-- a la app, solo existir como registro para que la agregación por empresa
-- tenga sentido), con un ticket propio.
--------------------------------------------------------------------------------

DECLARE
    v_id_empresa  NUMBER;
    v_id_cliente2 NUMBER;
    v_id_activo   NUMBER;
    v_id_orden    NUMBER;
BEGIN
    SELECT id_empresa INTO v_id_empresa
      FROM OP_EMPRESAS_CLIENTE
     WHERE nombre = 'Cliente Demo S.L.';

    INSERT INTO OP_CLIENTES (nombre, email, telefono, id_empresa, rol)
    VALUES ('Ana Torres', 'ana.torres@empresa-cliente.com', '600111222', v_id_empresa, 'CLIENTE')
    RETURNING id_cliente INTO v_id_cliente2;

    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'No llegan los correos desde esta mañana',
        p_descripcion    => 'El servidor de correo parece no estar entregando mensajes nuevos desde las 9am.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'ALTA'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET ID_CLIENTE = v_id_cliente2,
           SEVERIDAD = 'MAYOR',
           FECHA_CREACION = SYSDATE
     WHERE ID_ORDEN = v_id_orden;
END;
/

COMMIT;

--------------------------------------------------------------------------------
-- Verificación: ahora "Cliente Demo S.L." tiene 2 clientes y 5 tickets en
-- total, mientras que cliente_demo individualmente sigue teniendo 4.
--------------------------------------------------------------------------------
SELECT c.nombre AS cliente, o.id_orden, o.titulo, o.estado
  FROM OP_ORDENES_TRABAJO o
  JOIN OP_CLIENTES c ON c.id_cliente = o.id_cliente
 WHERE c.id_empresa = (SELECT id_empresa FROM OP_EMPRESAS_CLIENTE WHERE nombre = 'Cliente Demo S.L.')
 ORDER BY o.fecha_creacion DESC;
