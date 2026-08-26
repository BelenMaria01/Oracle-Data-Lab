--------------------------------------------------------------------------------
-- 17_DATOS_DEMO_TICKETS_CLIENTE_DEMO.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere que ya se hayan corrido:
--   07_DATOS_DEMO.sql          (activos de ejemplo)
--   15_CREAR_USUARIOS_PRUEBA.sql (crea el registro de OP_CLIENTES para
--                                 cliente_demo, empresa "Cliente Demo S.L.")
--
-- Motivo: las 8 órdenes de 12_DATOS_DEMO_ORDENES.sql se crearon todas sin
-- ID_CLIENTE (PKG_ORDENES.crear_orden no tiene ese parámetro; el ID_CLIENTE
-- se fuerza aparte cuando el ticket lo crea un cliente real desde la app).
-- Como resultado, "Mis Tickets" (página 21) y "Tickets de Mi Empresa"
-- (página 29) de cliente_demo aparecían siempre vacíos: el listado ya trae
-- TODOS los estados (no filtra por Estado, ver p00021), simplemente no
-- había ninguna orden con ID_CLIENTE = la suya.
--
-- Esta migración crea 4 órdenes NUEVAS (no toca las 8 de 12_...), atadas al
-- cliente_demo, pasando por 4 estados distintos vía PKG_ORDENES (nunca
-- INSERT directo), para poder ver el historial completo en el portal:
--   NUEVO       (recién creada, sin técnico)
--   EN_PROCESO  (asignada a jgarcia)
--   RESUELTO
--   CERRADO
--
-- NO es idempotente: cada corrida crea 4 órdenes nuevas.
--------------------------------------------------------------------------------

DECLARE
    v_id_cliente NUMBER;
    v_id_activo  NUMBER;
    v_id_tecnico NUMBER;
    v_id_orden   NUMBER;
BEGIN
    SELECT id_cliente INTO v_id_cliente
      FROM OP_CLIENTES
     WHERE usuario_apex = 'cliente_demo';

    SELECT id_tecnico INTO v_id_tecnico
      FROM OP_TECNICOS
     WHERE username = 'jgarcia';

    ----------------------------------------------------------------------
    -- 1. NUEVO — recién reportado, sin asignar
    ----------------------------------------------------------------------
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-RRHH-05';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'La impresora de RRHH no imprime en color',
        p_descripcion    => 'Desde ayer los documentos salen solo en blanco y negro aunque se selecciona color.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'cliente_demo'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET ID_CLIENTE = v_id_cliente,
           SEVERIDAD = 'MENOR',
           FECHA_CREACION = SYSDATE - 1
     WHERE ID_ORDEN = v_id_orden;

    ----------------------------------------------------------------------
    -- 2. EN_PROCESO — asignada y en curso
    ----------------------------------------------------------------------
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Lentitud al abrir el sistema de facturación',
        p_descripcion    => 'El sistema tarda más de un minuto en cargar la pantalla inicial desde el lunes.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'MEDIA',
        p_id_solicitante => 'cliente_demo'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET ID_CLIENTE = v_id_cliente,
           SEVERIDAD = 'MAYOR',
           FECHA_CREACION = SYSDATE - 3
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => v_id_tecnico,
        p_usuario    => 'cmms_admin'
    );

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'EN_PROCESO',
        p_usuario      => 'jgarcia'
    );

    ----------------------------------------------------------------------
    -- 3. RESUELTO
    ----------------------------------------------------------------------
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'PC-RRHH-05';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'No se puede acceder al VPN desde casa',
        p_descripcion    => 'La conexión VPN corporativa da error de autenticación al conectar en remoto.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'CORRECTIVO',
        p_prioridad      => 'ALTA',
        p_id_solicitante => 'cliente_demo'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET ID_CLIENTE = v_id_cliente,
           SEVERIDAD = 'MAYOR',
           FECHA_CREACION = SYSDATE - 7
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => v_id_tecnico,
        p_usuario    => 'cmms_admin'
    );

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'EN_PROCESO',
        p_usuario      => 'jgarcia'
    );

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'RESUELTO',
        p_usuario      => 'jgarcia'
    );

    ----------------------------------------------------------------------
    -- 4. CERRADO
    ----------------------------------------------------------------------
    SELECT id_activo INTO v_id_activo FROM OP_ACTIVOS WHERE nombre = 'SRV-DB-01';

    v_id_orden := PKG_ORDENES.crear_orden(
        p_titulo         => 'Solicitud de instalación de Office en equipo nuevo',
        p_descripcion    => 'Se entregó un equipo nuevo al área de RRHH y falta instalar el paquete Office.',
        p_id_activo      => v_id_activo,
        p_tipo           => 'PREVENTIVO',
        p_prioridad      => 'BAJA',
        p_id_solicitante => 'cliente_demo'
    );

    UPDATE OP_ORDENES_TRABAJO
       SET ID_CLIENTE = v_id_cliente,
           SEVERIDAD = 'TRIVIAL',
           FECHA_CREACION = SYSDATE - 14
     WHERE ID_ORDEN = v_id_orden;

    PKG_ORDENES.asignar_tecnico(
        p_id_orden   => v_id_orden,
        p_id_tecnico => v_id_tecnico,
        p_usuario    => 'cmms_admin'
    );

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'EN_PROCESO',
        p_usuario      => 'jgarcia'
    );

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'RESUELTO',
        p_usuario      => 'jgarcia'
    );

    PKG_ORDENES.cambiar_estado(
        p_id_orden     => v_id_orden,
        p_estado_nuevo => 'CERRADO',
        p_usuario      => 'cliente_demo'
    );
END;
/

COMMIT;

--------------------------------------------------------------------------------
-- Verificación
--------------------------------------------------------------------------------
SELECT o.id_orden, o.titulo, o.estado, o.prioridad,
       TO_CHAR(o.fecha_creacion,'DD/MM/YYYY') fecha_creacion
  FROM OP_ORDENES_TRABAJO o
  JOIN OP_CLIENTES c ON c.id_cliente = o.id_cliente
 WHERE c.usuario_apex = 'cliente_demo'
 ORDER BY o.fecha_creacion DESC;
