--------------------------------------------------------------------------------
-- 02_PAQUETES.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Todos los paquetes PL/SQL, consolidados y con los bugs ya corregidos:
--   - PKG_ACTIVOS: usa auditoría interna propia (no depende de la firma
--     real de PKG_AUDITORIA.registrar_evento, que causaba PLS-00306)
--   - PKG_REPORTING: usa OP_REPUESTOS.coste_unitario (la columna real;
--     la versión vieja usaba "precio_unitario", que no existe → ORA-00904)
--
-- Ejecutar DESPUÉS de 01_TABLAS.sql
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. PKG_AUDITORIA
-- Registro de eventos independiente de la transacción llamante
-- (así el log queda aunque el proceso principal haga rollback)
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_AUDITORIA AS

    PROCEDURE registrar_evento(
        p_tabla       IN VARCHAR2,
        p_id_registro IN NUMBER,
        p_accion      IN VARCHAR2,
        p_detalle     IN VARCHAR2 DEFAULT NULL,
        p_usuario     IN VARCHAR2 DEFAULT NULL
    );

END PKG_AUDITORIA;
/

CREATE OR REPLACE PACKAGE BODY PKG_AUDITORIA AS

    PROCEDURE registrar_evento(
        p_tabla       IN VARCHAR2,
        p_id_registro IN NUMBER,
        p_accion      IN VARCHAR2,
        p_detalle     IN VARCHAR2 DEFAULT NULL,
        p_usuario     IN VARCHAR2 DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO OP_AUDITORIA (NOMBRE_TABLA, ID_REGISTRO, ACCION, USUARIO, DETALLE)
        VALUES (p_tabla, p_id_registro, p_accion, NVL(p_usuario, USER), p_detalle);

        COMMIT;
    END registrar_evento;

END PKG_AUDITORIA;
/

--------------------------------------------------------------------------------
-- 2. PKG_ORDENES
-- Ciclo de vida completo de una orden de trabajo / ticket:
--   crear, cambiar estado (con historial), asignar técnico,
--   añadir/quitar repuestos (con impacto en stock)
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_ORDENES AS

    FUNCTION crear_orden(
        p_titulo         IN VARCHAR2,
        p_descripcion    IN VARCHAR2,
        p_id_activo      IN NUMBER,
        p_tipo           IN VARCHAR2 DEFAULT 'CORRECTIVO',
        p_prioridad      IN VARCHAR2 DEFAULT 'MEDIA',
        p_id_solicitante IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE cambiar_estado(
        p_id_orden      IN NUMBER,
        p_estado_nuevo  IN VARCHAR2,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE asignar_tecnico(
        p_id_orden      IN NUMBER,
        p_id_tecnico    IN NUMBER,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE anadir_repuesto(
        p_id_orden      IN NUMBER,
        p_id_repuesto   IN NUMBER,
        p_cantidad      IN NUMBER,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE quitar_repuesto(
        p_id_orden_repuesto IN NUMBER,
        p_usuario           IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE recalcular_coste_repuestos(p_id_orden IN NUMBER);

END PKG_ORDENES;
/

CREATE OR REPLACE PACKAGE BODY PKG_ORDENES AS

    FUNCTION crear_orden(
        p_titulo         IN VARCHAR2,
        p_descripcion    IN VARCHAR2,
        p_id_activo      IN NUMBER,
        p_tipo           IN VARCHAR2 DEFAULT 'CORRECTIVO',
        p_prioridad      IN VARCHAR2 DEFAULT 'MEDIA',
        p_id_solicitante IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_id_orden NUMBER;
    BEGIN
        INSERT INTO OP_ORDENES_TRABAJO (
            TITULO, DESCRIPCION, ID_ACTIVO, TIPO, PRIORIDAD, ID_SOLICITANTE
        ) VALUES (
            p_titulo, p_descripcion, p_id_activo, p_tipo, p_prioridad, p_id_solicitante
        )
        RETURNING ID_ORDEN INTO v_id_orden;

        INSERT INTO OP_ORDEN_HISTORIAL (ID_ORDEN, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO)
        VALUES (v_id_orden, NULL, 'NUEVO', NVL(p_id_solicitante, USER));

        PKG_AUDITORIA.registrar_evento('OP_ORDENES_TRABAJO', v_id_orden, 'INSERT',
            'Orden creada: ' || p_titulo, p_id_solicitante);

        RETURN v_id_orden;
    END crear_orden;


    PROCEDURE cambiar_estado(
        p_id_orden      IN NUMBER,
        p_estado_nuevo  IN VARCHAR2,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    ) IS
        v_estado_actual OP_ORDENES_TRABAJO.ESTADO%TYPE;
    BEGIN
        SELECT ESTADO INTO v_estado_actual
        FROM OP_ORDENES_TRABAJO
        WHERE ID_ORDEN = p_id_orden
        FOR UPDATE;

        UPDATE OP_ORDENES_TRABAJO
           SET ESTADO = p_estado_nuevo,
               FECHA_INICIO = CASE WHEN p_estado_nuevo = 'EN_PROCESO' AND FECHA_INICIO IS NULL
                                    THEN SYSDATE ELSE FECHA_INICIO END,
               FECHA_FIN    = CASE WHEN p_estado_nuevo IN ('RESUELTO','CERRADO')
                                    THEN SYSDATE ELSE FECHA_FIN END,
               TIEMPO_REAL_HORAS = CASE WHEN p_estado_nuevo IN ('RESUELTO','CERRADO') AND FECHA_INICIO IS NOT NULL
                                         THEN ROUND((SYSDATE - FECHA_INICIO) * 24, 2)
                                         ELSE TIEMPO_REAL_HORAS END
         WHERE ID_ORDEN = p_id_orden;

        INSERT INTO OP_ORDEN_HISTORIAL (ID_ORDEN, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO)
        VALUES (p_id_orden, v_estado_actual, p_estado_nuevo, NVL(p_usuario, USER));

        PKG_AUDITORIA.registrar_evento('OP_ORDENES_TRABAJO', p_id_orden, 'UPDATE',
            'Estado: ' || v_estado_actual || ' -> ' || p_estado_nuevo, p_usuario);
    END cambiar_estado;


    PROCEDURE asignar_tecnico(
        p_id_orden      IN NUMBER,
        p_id_tecnico    IN NUMBER,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE OP_ORDENES_TRABAJO
           SET ID_TECNICO_ASIGNADO = p_id_tecnico,
               FECHA_ASIGNACION = SYSDATE
         WHERE ID_ORDEN = p_id_orden;

        PKG_AUDITORIA.registrar_evento('OP_ORDENES_TRABAJO', p_id_orden, 'UPDATE',
            'Técnico asignado: ID ' || p_id_tecnico, p_usuario);
    END asignar_tecnico;


    PROCEDURE anadir_repuesto(
        p_id_orden      IN NUMBER,
        p_id_repuesto   IN NUMBER,
        p_cantidad      IN NUMBER,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    ) IS
        v_stock_actual   OP_REPUESTOS.STOCK_ACTUAL%TYPE;
        v_coste_unitario OP_REPUESTOS.COSTE_UNITARIO%TYPE;
    BEGIN
        SELECT STOCK_ACTUAL, COSTE_UNITARIO
          INTO v_stock_actual, v_coste_unitario
          FROM OP_REPUESTOS
         WHERE ID_REPUESTO = p_id_repuesto
           FOR UPDATE;

        IF v_stock_actual < p_cantidad THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Stock insuficiente. Disponible: ' || v_stock_actual || ', solicitado: ' || p_cantidad);
        END IF;

        INSERT INTO OP_ORDEN_REPUESTOS (ID_ORDEN, ID_REPUESTO, CANTIDAD, COSTE_UNITARIO_APLICADO)
        VALUES (p_id_orden, p_id_repuesto, p_cantidad, v_coste_unitario);

        UPDATE OP_REPUESTOS
           SET STOCK_ACTUAL = STOCK_ACTUAL - p_cantidad
         WHERE ID_REPUESTO = p_id_repuesto;

        INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, ID_ORDEN, MOTIVO, USUARIO)
        VALUES (p_id_repuesto, 'SALIDA', p_cantidad, p_id_orden, 'Consumo en orden de trabajo', NVL(p_usuario, USER));

        recalcular_coste_repuestos(p_id_orden);

        PKG_AUDITORIA.registrar_evento('OP_ORDEN_REPUESTOS', p_id_orden, 'INSERT',
            'Repuesto ' || p_id_repuesto || ' x' || p_cantidad, p_usuario);
    END anadir_repuesto;


    PROCEDURE quitar_repuesto(
        p_id_orden_repuesto IN NUMBER,
        p_usuario           IN VARCHAR2 DEFAULT NULL
    ) IS
        v_id_orden    OP_ORDEN_REPUESTOS.ID_ORDEN%TYPE;
        v_id_repuesto OP_ORDEN_REPUESTOS.ID_REPUESTO%TYPE;
        v_cantidad    OP_ORDEN_REPUESTOS.CANTIDAD%TYPE;
    BEGIN
        SELECT ID_ORDEN, ID_REPUESTO, CANTIDAD
          INTO v_id_orden, v_id_repuesto, v_cantidad
          FROM OP_ORDEN_REPUESTOS
         WHERE ID_ORDEN_REPUESTO = p_id_orden_repuesto;

        DELETE FROM OP_ORDEN_REPUESTOS WHERE ID_ORDEN_REPUESTO = p_id_orden_repuesto;

        UPDATE OP_REPUESTOS
           SET STOCK_ACTUAL = STOCK_ACTUAL + v_cantidad
         WHERE ID_REPUESTO = v_id_repuesto;

        INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, ID_ORDEN, MOTIVO, USUARIO)
        VALUES (v_id_repuesto, 'ENTRADA', v_cantidad, v_id_orden, 'Devolución - repuesto retirado de orden', NVL(p_usuario, USER));

        recalcular_coste_repuestos(v_id_orden);

        PKG_AUDITORIA.registrar_evento('OP_ORDEN_REPUESTOS', v_id_orden, 'DELETE',
            'Repuesto ' || v_id_repuesto || ' x' || v_cantidad || ' retirado', p_usuario);
    END quitar_repuesto;


    PROCEDURE recalcular_coste_repuestos(p_id_orden IN NUMBER) IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(CANTIDAD * COSTE_UNITARIO_APLICADO), 0)
          INTO v_total
          FROM OP_ORDEN_REPUESTOS
         WHERE ID_ORDEN = p_id_orden;

        UPDATE OP_ORDENES_TRABAJO
           SET COSTE_REPUESTOS = v_total
         WHERE ID_ORDEN = p_id_orden;
    END recalcular_coste_repuestos;

END PKG_ORDENES;
/

--------------------------------------------------------------------------------
-- 3. PKG_INVENTARIO
-- Entradas/salidas de almacén no ligadas a una orden (compras, ajustes)
-- y consulta de repuestos por debajo del stock mínimo (para el Dashboard)
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_INVENTARIO AS

    PROCEDURE entrada_stock(
        p_id_repuesto IN NUMBER,
        p_cantidad    IN NUMBER,
        p_motivo      IN VARCHAR2 DEFAULT 'Entrada de almacén',
        p_usuario     IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE salida_stock(
        p_id_repuesto IN NUMBER,
        p_cantidad    IN NUMBER,
        p_motivo      IN VARCHAR2 DEFAULT 'Salida de almacén',
        p_usuario     IN VARCHAR2 DEFAULT NULL
    );

    FUNCTION repuestos_bajo_minimo RETURN SYS_REFCURSOR;

    FUNCTION valor_total_inventario RETURN NUMBER;

END PKG_INVENTARIO;
/

CREATE OR REPLACE PACKAGE BODY PKG_INVENTARIO AS

    PROCEDURE entrada_stock(
        p_id_repuesto IN NUMBER,
        p_cantidad    IN NUMBER,
        p_motivo      IN VARCHAR2 DEFAULT 'Entrada de almacén',
        p_usuario     IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE OP_REPUESTOS
           SET STOCK_ACTUAL = STOCK_ACTUAL + p_cantidad
         WHERE ID_REPUESTO = p_id_repuesto;

        INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, USUARIO)
        VALUES (p_id_repuesto, 'ENTRADA', p_cantidad, p_motivo, NVL(p_usuario, USER));

        PKG_AUDITORIA.registrar_evento('OP_REPUESTOS', p_id_repuesto, 'UPDATE',
            'Entrada stock +' || p_cantidad, p_usuario);
    END entrada_stock;


    PROCEDURE salida_stock(
        p_id_repuesto IN NUMBER,
        p_cantidad    IN NUMBER,
        p_motivo      IN VARCHAR2 DEFAULT 'Salida de almacén',
        p_usuario     IN VARCHAR2 DEFAULT NULL
    ) IS
        v_stock_actual OP_REPUESTOS.STOCK_ACTUAL%TYPE;
    BEGIN
        SELECT STOCK_ACTUAL INTO v_stock_actual
          FROM OP_REPUESTOS WHERE ID_REPUESTO = p_id_repuesto FOR UPDATE;

        IF v_stock_actual < p_cantidad THEN
            RAISE_APPLICATION_ERROR(-20002,
                'Stock insuficiente. Disponible: ' || v_stock_actual || ', solicitado: ' || p_cantidad);
        END IF;

        UPDATE OP_REPUESTOS
           SET STOCK_ACTUAL = STOCK_ACTUAL - p_cantidad
         WHERE ID_REPUESTO = p_id_repuesto;

        INSERT INTO OP_MOVIMIENTOS_STOCK (ID_REPUESTO, TIPO_MOVIMIENTO, CANTIDAD, MOTIVO, USUARIO)
        VALUES (p_id_repuesto, 'SALIDA', p_cantidad, p_motivo, NVL(p_usuario, USER));

        PKG_AUDITORIA.registrar_evento('OP_REPUESTOS', p_id_repuesto, 'UPDATE',
            'Salida stock -' || p_cantidad, p_usuario);
    END salida_stock;


    FUNCTION repuestos_bajo_minimo RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT ID_REPUESTO, CODIGO, NOMBRE, STOCK_ACTUAL, STOCK_MINIMO
              FROM OP_REPUESTOS
             WHERE STOCK_ACTUAL < STOCK_MINIMO
             ORDER BY (STOCK_MINIMO - STOCK_ACTUAL) DESC;
        RETURN v_cursor;
    END repuestos_bajo_minimo;


    FUNCTION valor_total_inventario RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(STOCK_ACTUAL * COSTE_UNITARIO), 0)
        INTO v_total
        FROM OP_REPUESTOS;

        RETURN v_total;
    END valor_total_inventario;

END PKG_INVENTARIO;
/

--------------------------------------------------------------------------------
-- 4. PKG_ACTIVOS
-- Alta, cambio de estado y baja de un activo (con validación de que no
-- tenga órdenes de trabajo abiertas antes de darlo de baja).
-- Usa auditoría propia (registrar_auditoria_interna) en vez de depender
-- de la firma de PKG_AUDITORIA, para no arriesgar un PLS-00306.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_ACTIVOS AS

    FUNCTION dar_alta_activo (
        p_nombre               IN OP_ACTIVOS.nombre%TYPE,
        p_id_tipo_activo       IN OP_ACTIVOS.id_tipo_activo%TYPE,
        p_id_ubicacion         IN OP_ACTIVOS.id_ubicacion%TYPE,
        p_id_proveedor         IN OP_ACTIVOS.id_proveedor%TYPE DEFAULT NULL,
        p_id_tecnico_resp      IN OP_ACTIVOS.id_tecnico_responsable%TYPE DEFAULT NULL,
        p_coste_adquisicion    IN OP_ACTIVOS.coste_adquisicion%TYPE DEFAULT NULL,
        p_usuario              IN VARCHAR2 DEFAULT NULL
    ) RETURN OP_ACTIVOS.id_activo%TYPE;

    PROCEDURE cambiar_estado_activo (
        p_id_activo     IN OP_ACTIVOS.id_activo%TYPE,
        p_estado_nuevo  IN OP_ACTIVOS.estado%TYPE,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE dar_baja_activo (
        p_id_activo IN OP_ACTIVOS.id_activo%TYPE,
        p_usuario   IN VARCHAR2 DEFAULT NULL
    );

END PKG_ACTIVOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_ACTIVOS AS

    PROCEDURE registrar_auditoria_interna (
        p_id_registro IN NUMBER,
        p_accion      IN VARCHAR2,
        p_detalle     IN VARCHAR2,
        p_usuario     IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO OP_AUDITORIA (
            nombre_tabla, id_registro, accion, detalle, usuario, fecha_evento
        ) VALUES (
            'OP_ACTIVOS', p_id_registro, p_accion, p_detalle, NVL(p_usuario, USER), SYSDATE
        );
        COMMIT;
    END registrar_auditoria_interna;


    FUNCTION dar_alta_activo (
        p_nombre               IN OP_ACTIVOS.nombre%TYPE,
        p_id_tipo_activo       IN OP_ACTIVOS.id_tipo_activo%TYPE,
        p_id_ubicacion         IN OP_ACTIVOS.id_ubicacion%TYPE,
        p_id_proveedor         IN OP_ACTIVOS.id_proveedor%TYPE DEFAULT NULL,
        p_id_tecnico_resp      IN OP_ACTIVOS.id_tecnico_responsable%TYPE DEFAULT NULL,
        p_coste_adquisicion    IN OP_ACTIVOS.coste_adquisicion%TYPE DEFAULT NULL,
        p_usuario              IN VARCHAR2 DEFAULT NULL
    ) RETURN OP_ACTIVOS.id_activo%TYPE
    IS
        v_id_activo OP_ACTIVOS.id_activo%TYPE;
    BEGIN
        INSERT INTO OP_ACTIVOS (
            nombre, id_tipo_activo, id_ubicacion, id_proveedor,
            id_tecnico_responsable, coste_adquisicion, estado, fecha_alta
        ) VALUES (
            p_nombre, p_id_tipo_activo, p_id_ubicacion, p_id_proveedor,
            p_id_tecnico_resp, p_coste_adquisicion, 'ACTIVO', SYSDATE
        )
        RETURNING id_activo INTO v_id_activo;

        registrar_auditoria_interna(
            p_id_registro => v_id_activo,
            p_accion      => 'ALTA',
            p_detalle     => 'Alta de activo: ' || p_nombre,
            p_usuario     => p_usuario
        );

        RETURN v_id_activo;
    END dar_alta_activo;


    PROCEDURE cambiar_estado_activo (
        p_id_activo     IN OP_ACTIVOS.id_activo%TYPE,
        p_estado_nuevo  IN OP_ACTIVOS.estado%TYPE,
        p_usuario       IN VARCHAR2 DEFAULT NULL
    ) IS
        v_estado_anterior OP_ACTIVOS.estado%TYPE;
    BEGIN
        IF p_estado_nuevo NOT IN ('ACTIVO', 'EN_REPARACION', 'ALMACEN', 'BAJA') THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Estado no válido: ' || p_estado_nuevo ||
                '. Valores permitidos: ACTIVO, EN_REPARACION, ALMACEN, BAJA.');
        END IF;

        SELECT estado INTO v_estado_anterior
        FROM OP_ACTIVOS
        WHERE id_activo = p_id_activo
        FOR UPDATE;

        UPDATE OP_ACTIVOS
        SET estado = p_estado_nuevo
        WHERE id_activo = p_id_activo;

        registrar_auditoria_interna(
            p_id_registro => p_id_activo,
            p_accion      => 'CAMBIO_ESTADO',
            p_detalle     => v_estado_anterior || ' -> ' || p_estado_nuevo,
            p_usuario     => p_usuario
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No existe el activo con id ' || p_id_activo);
    END cambiar_estado_activo;


    PROCEDURE dar_baja_activo (
        p_id_activo IN OP_ACTIVOS.id_activo%TYPE,
        p_usuario   IN VARCHAR2 DEFAULT NULL
    ) IS
        v_ordenes_abiertas NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_ordenes_abiertas
        FROM OP_ORDENES_TRABAJO
        WHERE id_activo = p_id_activo
          AND estado IN ('NUEVO', 'EN_PROCESO', 'REABIERTO');

        IF v_ordenes_abiertas > 0 THEN
            RAISE_APPLICATION_ERROR(-20003,
                'No se puede dar de baja el activo ' || p_id_activo ||
                ': tiene ' || v_ordenes_abiertas || ' orden(es) de trabajo abierta(s).');
        END IF;

        cambiar_estado_activo(p_id_activo, 'BAJA', p_usuario);
    END dar_baja_activo;

END PKG_ACTIVOS;
/

--------------------------------------------------------------------------------
-- 5. PKG_REPORTING
-- Funciones de agregación para dashboards e informes.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_REPORTING AS

    FUNCTION coste_periodo (
        p_fecha_ini IN DATE,
        p_fecha_fin IN DATE
    ) RETURN NUMBER;

END PKG_REPORTING;
/

CREATE OR REPLACE PACKAGE BODY PKG_REPORTING AS

    FUNCTION coste_periodo (
        p_fecha_ini IN DATE,
        p_fecha_fin IN DATE
    ) RETURN NUMBER IS
        v_total NUMBER;
    BEGIN
        SELECT NVL(SUM(coste_total), 0)
        INTO v_total
        FROM OP_ORDENES_TRABAJO
        WHERE fecha_creacion BETWEEN p_fecha_ini AND p_fecha_fin;

        RETURN v_total;
    END coste_periodo;

END PKG_REPORTING;
/

--------------------------------------------------------------------------------
-- 6. PKG_NOTIFICACIONES
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_NOTIFICACIONES AS

    PROCEDURE generar_notificacion (
        p_tipo               IN VARCHAR2,
        p_mensaje            IN VARCHAR2,
        p_id_registro        IN NUMBER DEFAULT NULL,
        p_nombre_tabla       IN VARCHAR2 DEFAULT NULL,
        p_id_tecnico_destino IN NUMBER DEFAULT NULL
    );

    PROCEDURE marcar_leida (p_id_notificacion IN NUMBER);

    PROCEDURE marcar_todas_leidas (p_id_tecnico IN NUMBER);

    FUNCTION contar_no_leidas (p_id_tecnico IN NUMBER) RETURN NUMBER;

END PKG_NOTIFICACIONES;
/

CREATE OR REPLACE PACKAGE BODY PKG_NOTIFICACIONES AS

    PROCEDURE generar_notificacion (
        p_tipo               IN VARCHAR2,
        p_mensaje            IN VARCHAR2,
        p_id_registro        IN NUMBER DEFAULT NULL,
        p_nombre_tabla       IN VARCHAR2 DEFAULT NULL,
        p_id_tecnico_destino IN NUMBER DEFAULT NULL
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO OP_NOTIFICACIONES (
            tipo, mensaje, id_registro, nombre_tabla, id_tecnico_destino
        ) VALUES (
            p_tipo, p_mensaje, p_id_registro, p_nombre_tabla, p_id_tecnico_destino
        );
        COMMIT;
    END generar_notificacion;


    PROCEDURE marcar_leida (p_id_notificacion IN NUMBER) IS
    BEGIN
        UPDATE OP_NOTIFICACIONES
        SET leida = 'S'
        WHERE id_notificacion = p_id_notificacion;
    END marcar_leida;


    PROCEDURE marcar_todas_leidas (p_id_tecnico IN NUMBER) IS
    BEGIN
        UPDATE OP_NOTIFICACIONES
        SET leida = 'S'
        WHERE leida = 'N'
          AND (id_tecnico_destino = p_id_tecnico OR id_tecnico_destino IS NULL);
    END marcar_todas_leidas;


    FUNCTION contar_no_leidas (p_id_tecnico IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM OP_NOTIFICACIONES
        WHERE leida = 'N'
          AND (id_tecnico_destino = p_id_tecnico OR id_tecnico_destino IS NULL);

        RETURN v_count;
    END contar_no_leidas;

END PKG_NOTIFICACIONES;
/

--------------------------------------------------------------------------------
-- 7. Verificación — todos deben mostrar VALID
--------------------------------------------------------------------------------

SELECT object_name, object_type, status
FROM user_objects
WHERE object_type LIKE 'PACKAGE%'
ORDER BY object_name, object_type;