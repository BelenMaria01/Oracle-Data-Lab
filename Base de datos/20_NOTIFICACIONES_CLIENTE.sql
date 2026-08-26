--------------------------------------------------------------------------------
-- 20_NOTIFICACIONES_CLIENTE.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere que ya se hayan corrido:
--   01_TABLAS.sql, 02_PAQUETES.sql, 03_TRIGGERS.sql
--
-- Motivo: OP_NOTIFICACIONES solo tenía ID_TECNICO_DESTINO — no existía
-- forma de notificar a un cliente cuando cambia el estado de su ticket.
-- Mismo criterio que 19_ALTER_ACTIVOS_EMPRESA.sql: se resuelve con un
-- cambio de esquema real, no con un parche.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. Columna nueva, NULLABLE, no rompe nada existente
--------------------------------------------------------------------------------

ALTER TABLE OP_NOTIFICACIONES ADD (
    ID_CLIENTE_DESTINO NUMBER
);
ALTER TABLE OP_NOTIFICACIONES ADD CONSTRAINT FK_NOTIF_CLIENTE
    FOREIGN KEY (ID_CLIENTE_DESTINO) REFERENCES OP_CLIENTES(ID_CLIENTE);
COMMENT ON COLUMN OP_NOTIFICACIONES.ID_CLIENTE_DESTINO IS
    'NULL si la notificación es para staff (ID_TECNICO_DESTINO) o global; con valor si es para un cliente puntual del portal';

--------------------------------------------------------------------------------
-- 2. PKG_NOTIFICACIONES: se agrega el parámetro de cliente a las 4
--    subrutinas. Los parámetros nuevos van al final y con DEFAULT, así que
--    las llamadas existentes en la app (p01, p17) siguen funcionando sin
--    tocarlas.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_NOTIFICACIONES AS

    PROCEDURE generar_notificacion (
        p_tipo               IN VARCHAR2,
        p_mensaje            IN VARCHAR2,
        p_id_registro        IN NUMBER DEFAULT NULL,
        p_nombre_tabla       IN VARCHAR2 DEFAULT NULL,
        p_id_tecnico_destino IN NUMBER DEFAULT NULL,
        p_id_cliente_destino IN NUMBER DEFAULT NULL
    );

    PROCEDURE marcar_leida (p_id_notificacion IN NUMBER);

    PROCEDURE marcar_todas_leidas (
        p_id_tecnico IN NUMBER DEFAULT NULL,
        p_id_cliente IN NUMBER DEFAULT NULL
    );

    FUNCTION contar_no_leidas (
        p_id_tecnico IN NUMBER DEFAULT NULL,
        p_id_cliente IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

END PKG_NOTIFICACIONES;
/

CREATE OR REPLACE PACKAGE BODY PKG_NOTIFICACIONES AS

    PROCEDURE generar_notificacion (
        p_tipo               IN VARCHAR2,
        p_mensaje            IN VARCHAR2,
        p_id_registro        IN NUMBER DEFAULT NULL,
        p_nombre_tabla       IN VARCHAR2 DEFAULT NULL,
        p_id_tecnico_destino IN NUMBER DEFAULT NULL,
        p_id_cliente_destino IN NUMBER DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO OP_NOTIFICACIONES (
            tipo, mensaje, id_registro, nombre_tabla, id_tecnico_destino, id_cliente_destino
        ) VALUES (
            p_tipo, p_mensaje, p_id_registro, p_nombre_tabla, p_id_tecnico_destino, p_id_cliente_destino
        );
        COMMIT;
    END generar_notificacion;


    PROCEDURE marcar_leida (p_id_notificacion IN NUMBER) IS
    BEGIN
        UPDATE OP_NOTIFICACIONES
           SET leida = 'S'
         WHERE id_notificacion = p_id_notificacion;
    END marcar_leida;


    PROCEDURE marcar_todas_leidas (
        p_id_tecnico IN NUMBER DEFAULT NULL,
        p_id_cliente IN NUMBER DEFAULT NULL
    ) IS
    BEGIN
        UPDATE OP_NOTIFICACIONES
           SET leida = 'S'
         WHERE (p_id_tecnico IS NOT NULL AND id_tecnico_destino = p_id_tecnico)
            OR (p_id_cliente IS NOT NULL AND id_cliente_destino = p_id_cliente);
    END marcar_todas_leidas;


    FUNCTION contar_no_leidas (
        p_id_tecnico IN NUMBER DEFAULT NULL,
        p_id_cliente IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
          FROM OP_NOTIFICACIONES
         WHERE leida = 'N'
           AND (
                (p_id_tecnico IS NOT NULL AND id_tecnico_destino = p_id_tecnico)
             OR (p_id_cliente IS NOT NULL AND id_cliente_destino = p_id_cliente)
           );
        RETURN v_count;
    END contar_no_leidas;

END PKG_NOTIFICACIONES;
/

--------------------------------------------------------------------------------
-- 3. Trigger: notifica al cliente cuando cambia el estado de su ticket
--------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER TRG_OP_ORDENES_NOTIF_CLIENTE
AFTER UPDATE OF estado ON OP_ORDENES_TRABAJO
FOR EACH ROW
WHEN (NEW.id_cliente IS NOT NULL AND NEW.estado != OLD.estado)
BEGIN
    PKG_NOTIFICACIONES.generar_notificacion(
        p_tipo               => 'ESTADO_TICKET',
        p_mensaje            => 'Tu ticket #' || :NEW.id_orden || ' ("' || :NEW.titulo || '") cambió a estado ' || :NEW.estado || '.',
        p_id_registro        => :NEW.id_orden,
        p_nombre_tabla       => 'OP_ORDENES_TRABAJO',
        p_id_cliente_destino => :NEW.id_cliente
    );
END;
/

--------------------------------------------------------------------------------
-- Verificación
--------------------------------------------------------------------------------
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN ('PKG_NOTIFICACIONES', 'TRG_OP_ORDENES_NOTIF_CLIENTE')
 ORDER BY object_type, object_name;
