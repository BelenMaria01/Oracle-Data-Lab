--------------------------------------------------------------------------------
-- 04_CALENDARIO_KB.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. NO reemplaza a 01_TABLAS.sql / 02_PAQUETES.sql /
-- 03_TRIGGERS.sql, los complementa. Ejecutar DESPUÉS de los 3 scripts
-- anteriores, sobre la base de datos ya en uso (no requiere reset).
--
-- Contenido:
--   1. Tabla OP_MANTENIMIENTOS_PROGRAMADOS  (Calendario de mantenimientos)
--   2. Columna nueva en OP_ORDENES_TRABAJO  (trazabilidad hacia la programación)
--   3. Tabla OP_ARTICULOS_KB                (Base de Conocimiento interna)
--   4. Índices sobre las nuevas claves foráneas
--   5. PKG_MANTENIMIENTOS                   (programar, generar órdenes vencidas)
--   6. PKG_KB                               (crear/buscar artículos, contador vistas)
--   7. PKG_REPORTING ampliado               (KPIs de Home: por estado, tiempo medio)
--   8. Vistas VW_KPI_*                      (para binding directo en regiones APEX)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. CALENDARIO DE MANTENIMIENTOS PROGRAMADOS
--------------------------------------------------------------------------------

CREATE TABLE OP_MANTENIMIENTOS_PROGRAMADOS (
    ID_PROGRAMACION       NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TITULO                 VARCHAR2(200)   NOT NULL,
    DESCRIPCION             VARCHAR2(2000),
    ID_ACTIVO               NUMBER          NOT NULL,
    FRECUENCIA               VARCHAR2(20)    NOT NULL,
    INTERVALO_DIAS           NUMBER,
    PROXIMA_FECHA            DATE            NOT NULL,
    ULTIMA_GENERACION        DATE,
    ID_TECNICO_ASIGNADO      NUMBER,
    PRIORIDAD                VARCHAR2(10)    DEFAULT 'MEDIA' NOT NULL,
    ACTIVO                   VARCHAR2(1)     DEFAULT 'Y' NOT NULL CHECK (ACTIVO IN ('Y','N')),
    FECHA_ALTA                DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT CK_PROG_FRECUENCIA CHECK (FRECUENCIA IN
        ('SEMANAL','QUINCENAL','MENSUAL','TRIMESTRAL','SEMESTRAL','ANUAL','PERSONALIZADA')),
    CONSTRAINT CK_PROG_PRIORIDAD CHECK (PRIORIDAD IN ('BAJA','MEDIA','ALTA','CRITICA')),
    CONSTRAINT CK_PROG_INTERVALO CHECK (
        (FRECUENCIA != 'PERSONALIZADA') OR (INTERVALO_DIAS IS NOT NULL AND INTERVALO_DIAS > 0)
    ),
    CONSTRAINT FK_PROG_ACTIVO   FOREIGN KEY (ID_ACTIVO) REFERENCES OP_ACTIVOS(ID_ACTIVO),
    CONSTRAINT FK_PROG_TECNICO  FOREIGN KEY (ID_TECNICO_ASIGNADO) REFERENCES OP_TECNICOS(ID_TECNICO)
);
COMMENT ON TABLE OP_MANTENIMIENTOS_PROGRAMADOS IS
    'Calendario de mantenimientos preventivos recurrentes. Cada fila es una regla (activo + frecuencia); al llegar PROXIMA_FECHA se genera automáticamente una OP_ORDENES_TRABAJO de TIPO=PREVENTIVO vía PKG_MANTENIMIENTOS.generar_ordenes_vencidas';

--------------------------------------------------------------------------------
-- 2. TRAZABILIDAD: qué orden de trabajo vino de qué programación
--    (columna nueva, nullable, no rompe nada de lo ya existente)
--------------------------------------------------------------------------------

ALTER TABLE OP_ORDENES_TRABAJO ADD (
    ID_PROGRAMACION NUMBER
);
ALTER TABLE OP_ORDENES_TRABAJO ADD CONSTRAINT FK_OT_PROGRAMACION
    FOREIGN KEY (ID_PROGRAMACION) REFERENCES OP_MANTENIMIENTOS_PROGRAMADOS(ID_PROGRAMACION);
COMMENT ON COLUMN OP_ORDENES_TRABAJO.ID_PROGRAMACION IS
    'NULL si la orden se creó manualmente; con valor si la generó el calendario de mantenimientos';

--------------------------------------------------------------------------------
-- 3. BASE DE CONOCIMIENTO INTERNA
--------------------------------------------------------------------------------

CREATE TABLE OP_ARTICULOS_KB (
    ID_ARTICULO           NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TITULO                 VARCHAR2(200)   NOT NULL,
    CONTENIDO               CLOB            NOT NULL,
    ID_TIPO_ACTIVO           NUMBER,
    ETIQUETAS                 VARCHAR2(500),
    ID_TECNICO_AUTOR          NUMBER         NOT NULL,
    VISTAS                    NUMBER         DEFAULT 0 NOT NULL,
    ACTIVO                    VARCHAR2(1)    DEFAULT 'Y' NOT NULL CHECK (ACTIVO IN ('Y','N')),
    FECHA_PUBLICACION          DATE          DEFAULT SYSDATE NOT NULL,
    FECHA_ACTUALIZACION        DATE,
    CONSTRAINT FK_KB_TIPO  FOREIGN KEY (ID_TIPO_ACTIVO) REFERENCES OP_TIPOS_ACTIVO(ID_TIPO_ACTIVO),
    CONSTRAINT FK_KB_AUTOR FOREIGN KEY (ID_TECNICO_AUTOR) REFERENCES OP_TECNICOS(ID_TECNICO)
);
COMMENT ON TABLE OP_ARTICULOS_KB IS
    'Base de conocimiento interna: procedimientos, soluciones a incidencias recurrentes, guías. ETIQUETAS es una lista simple separada por comas para búsqueda (ej: impresora,atasco,hp)';

--------------------------------------------------------------------------------
-- 4. ÍNDICES SOBRE LAS NUEVAS CLAVES FORÁNEAS
--------------------------------------------------------------------------------

CREATE INDEX IX_PROG_ACTIVO      ON OP_MANTENIMIENTOS_PROGRAMADOS(ID_ACTIVO);
CREATE INDEX IX_PROG_TECNICO     ON OP_MANTENIMIENTOS_PROGRAMADOS(ID_TECNICO_ASIGNADO);
CREATE INDEX IX_PROG_PROXFECHA   ON OP_MANTENIMIENTOS_PROGRAMADOS(PROXIMA_FECHA);

CREATE INDEX IX_OT_PROGRAMACION  ON OP_ORDENES_TRABAJO(ID_PROGRAMACION);

CREATE INDEX IX_KB_TIPO          ON OP_ARTICULOS_KB(ID_TIPO_ACTIVO);
CREATE INDEX IX_KB_AUTOR         ON OP_ARTICULOS_KB(ID_TECNICO_AUTOR);

--------------------------------------------------------------------------------
-- 5. PKG_MANTENIMIENTOS
-- Alta de programaciones y generación automática de órdenes cuando vencen.
-- generar_ordenes_vencidas() está pensada para llamarse desde un
-- DBMS_SCHEDULER job diario (ver nota al final del script).
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_MANTENIMIENTOS AS

    FUNCTION programar (
        p_titulo              IN OP_MANTENIMIENTOS_PROGRAMADOS.titulo%TYPE,
        p_id_activo            IN OP_MANTENIMIENTOS_PROGRAMADOS.id_activo%TYPE,
        p_frecuencia            IN OP_MANTENIMIENTOS_PROGRAMADOS.frecuencia%TYPE,
        p_proxima_fecha          IN DATE,
        p_intervalo_dias          IN NUMBER DEFAULT NULL,
        p_id_tecnico_asignado      IN NUMBER DEFAULT NULL,
        p_descripcion               IN VARCHAR2 DEFAULT NULL,
        p_prioridad                  IN VARCHAR2 DEFAULT 'MEDIA',
        p_usuario                     IN VARCHAR2 DEFAULT NULL
    ) RETURN OP_MANTENIMIENTOS_PROGRAMADOS.id_programacion%TYPE;

    PROCEDURE desactivar (
        p_id_programacion IN NUMBER,
        p_usuario         IN VARCHAR2 DEFAULT NULL
    );

    -- Calcula la fecha del próximo ciclo a partir de una fecha base y la frecuencia
    FUNCTION calcular_siguiente_fecha (
        p_fecha_base      IN DATE,
        p_frecuencia       IN VARCHAR2,
        p_intervalo_dias    IN NUMBER DEFAULT NULL
    ) RETURN DATE;

    -- Recorre las programaciones activas con PROXIMA_FECHA <= SYSDATE,
    -- genera una orden PREVENTIVO por cada una y avanza su PROXIMA_FECHA.
    -- Devuelve la cantidad de órdenes generadas.
    FUNCTION generar_ordenes_vencidas RETURN NUMBER;

END PKG_MANTENIMIENTOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_MANTENIMIENTOS AS

    FUNCTION programar (
        p_titulo              IN OP_MANTENIMIENTOS_PROGRAMADOS.titulo%TYPE,
        p_id_activo            IN OP_MANTENIMIENTOS_PROGRAMADOS.id_activo%TYPE,
        p_frecuencia            IN OP_MANTENIMIENTOS_PROGRAMADOS.frecuencia%TYPE,
        p_proxima_fecha          IN DATE,
        p_intervalo_dias          IN NUMBER DEFAULT NULL,
        p_id_tecnico_asignado      IN NUMBER DEFAULT NULL,
        p_descripcion               IN VARCHAR2 DEFAULT NULL,
        p_prioridad                  IN VARCHAR2 DEFAULT 'MEDIA',
        p_usuario                     IN VARCHAR2 DEFAULT NULL
    ) RETURN OP_MANTENIMIENTOS_PROGRAMADOS.id_programacion%TYPE IS
        v_id_programacion OP_MANTENIMIENTOS_PROGRAMADOS.id_programacion%TYPE;
    BEGIN
        INSERT INTO OP_MANTENIMIENTOS_PROGRAMADOS (
            titulo, id_activo, frecuencia, proxima_fecha, intervalo_dias,
            id_tecnico_asignado, descripcion, prioridad
        ) VALUES (
            p_titulo, p_id_activo, p_frecuencia, p_proxima_fecha, p_intervalo_dias,
            p_id_tecnico_asignado, p_descripcion, p_prioridad
        )
        RETURNING id_programacion INTO v_id_programacion;

        PKG_AUDITORIA.registrar_evento('OP_MANTENIMIENTOS_PROGRAMADOS', v_id_programacion, 'INSERT',
            'Programación creada: ' || p_titulo, p_usuario);

        RETURN v_id_programacion;
    END programar;


    PROCEDURE desactivar (
        p_id_programacion IN NUMBER,
        p_usuario         IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE OP_MANTENIMIENTOS_PROGRAMADOS
           SET activo = 'N'
         WHERE id_programacion = p_id_programacion;

        PKG_AUDITORIA.registrar_evento('OP_MANTENIMIENTOS_PROGRAMADOS', p_id_programacion, 'UPDATE',
            'Programación desactivada', p_usuario);
    END desactivar;


    FUNCTION calcular_siguiente_fecha (
        p_fecha_base      IN DATE,
        p_frecuencia       IN VARCHAR2,
        p_intervalo_dias    IN NUMBER DEFAULT NULL
    ) RETURN DATE IS
    BEGIN
        RETURN CASE p_frecuencia
            WHEN 'SEMANAL'      THEN p_fecha_base + 7
            WHEN 'QUINCENAL'    THEN p_fecha_base + 15
            WHEN 'MENSUAL'      THEN ADD_MONTHS(p_fecha_base, 1)
            WHEN 'TRIMESTRAL'   THEN ADD_MONTHS(p_fecha_base, 3)
            WHEN 'SEMESTRAL'    THEN ADD_MONTHS(p_fecha_base, 6)
            WHEN 'ANUAL'        THEN ADD_MONTHS(p_fecha_base, 12)
            WHEN 'PERSONALIZADA' THEN p_fecha_base + NVL(p_intervalo_dias, 30)
            ELSE p_fecha_base + 30
        END;
    END calcular_siguiente_fecha;


    FUNCTION generar_ordenes_vencidas RETURN NUMBER IS
        v_generadas   NUMBER := 0;
        v_id_orden    OP_ORDENES_TRABAJO.id_orden%TYPE;
    BEGIN
        FOR r IN (
            SELECT id_programacion, titulo, descripcion, id_activo, frecuencia,
                   intervalo_dias, id_tecnico_asignado, prioridad, proxima_fecha
              FROM OP_MANTENIMIENTOS_PROGRAMADOS
             WHERE activo = 'Y'
               AND proxima_fecha <= SYSDATE
        ) LOOP
            v_id_orden := PKG_ORDENES.crear_orden(
                p_titulo      => '[Preventivo] ' || r.titulo,
                p_descripcion => r.descripcion,
                p_id_activo   => r.id_activo,
                p_tipo        => 'PREVENTIVO',
                p_prioridad   => r.prioridad
            );

            UPDATE OP_ORDENES_TRABAJO
               SET id_programacion = r.id_programacion,
                   id_tecnico_asignado = r.id_tecnico_asignado,
                   fecha_asignacion = CASE WHEN r.id_tecnico_asignado IS NOT NULL
                                            THEN SYSDATE ELSE NULL END
             WHERE id_orden = v_id_orden;

            UPDATE OP_MANTENIMIENTOS_PROGRAMADOS
               SET ultima_generacion = SYSDATE,
                   proxima_fecha = calcular_siguiente_fecha(r.proxima_fecha, r.frecuencia, r.intervalo_dias)
             WHERE id_programacion = r.id_programacion;

            v_generadas := v_generadas + 1;
        END LOOP;

        RETURN v_generadas;
    END generar_ordenes_vencidas;

END PKG_MANTENIMIENTOS;
/

--------------------------------------------------------------------------------
-- 6. PKG_KB
-- Alta de artículos y contador de vistas (autónomo para no afectar la
-- transacción de quien está leyendo el artículo)
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_KB AS

    FUNCTION crear_articulo (
        p_titulo            IN OP_ARTICULOS_KB.titulo%TYPE,
        p_contenido          IN CLOB,
        p_id_tecnico_autor    IN OP_ARTICULOS_KB.id_tecnico_autor%TYPE,
        p_id_tipo_activo       IN NUMBER DEFAULT NULL,
        p_etiquetas             IN VARCHAR2 DEFAULT NULL
    ) RETURN OP_ARTICULOS_KB.id_articulo%TYPE;

    PROCEDURE registrar_vista (p_id_articulo IN NUMBER);

    PROCEDURE actualizar_articulo (
        p_id_articulo IN NUMBER,
        p_titulo      IN VARCHAR2,
        p_contenido   IN CLOB,
        p_etiquetas   IN VARCHAR2 DEFAULT NULL
    );

END PKG_KB;
/

CREATE OR REPLACE PACKAGE BODY PKG_KB AS

    FUNCTION crear_articulo (
        p_titulo            IN OP_ARTICULOS_KB.titulo%TYPE,
        p_contenido          IN CLOB,
        p_id_tecnico_autor    IN OP_ARTICULOS_KB.id_tecnico_autor%TYPE,
        p_id_tipo_activo       IN NUMBER DEFAULT NULL,
        p_etiquetas             IN VARCHAR2 DEFAULT NULL
    ) RETURN OP_ARTICULOS_KB.id_articulo%TYPE IS
        v_id_articulo OP_ARTICULOS_KB.id_articulo%TYPE;
    BEGIN
        INSERT INTO OP_ARTICULOS_KB (
            titulo, contenido, id_tecnico_autor, id_tipo_activo, etiquetas
        ) VALUES (
            p_titulo, p_contenido, p_id_tecnico_autor, p_id_tipo_activo, p_etiquetas
        )
        RETURNING id_articulo INTO v_id_articulo;

        PKG_AUDITORIA.registrar_evento('OP_ARTICULOS_KB', v_id_articulo, 'INSERT',
            'Artículo creado: ' || p_titulo, NULL);

        RETURN v_id_articulo;
    END crear_articulo;


    PROCEDURE registrar_vista (p_id_articulo IN NUMBER) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        UPDATE OP_ARTICULOS_KB
           SET vistas = vistas + 1
         WHERE id_articulo = p_id_articulo;
        COMMIT;
    END registrar_vista;


    PROCEDURE actualizar_articulo (
        p_id_articulo IN NUMBER,
        p_titulo      IN VARCHAR2,
        p_contenido   IN CLOB,
        p_etiquetas   IN VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        UPDATE OP_ARTICULOS_KB
           SET titulo = p_titulo,
               contenido = p_contenido,
               etiquetas = p_etiquetas,
               fecha_actualizacion = SYSDATE
         WHERE id_articulo = p_id_articulo;

        PKG_AUDITORIA.registrar_evento('OP_ARTICULOS_KB', p_id_articulo, 'UPDATE',
            'Artículo actualizado: ' || p_titulo, NULL);
    END actualizar_articulo;

END PKG_KB;
/

--------------------------------------------------------------------------------
-- 7. PKG_REPORTING — ampliado con KPIs para el dashboard de Home
--    (CREATE OR REPLACE es seguro: conserva coste_periodo ya existente
--    y agrega las funciones nuevas)
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_REPORTING AS

    FUNCTION coste_periodo (
        p_fecha_ini IN DATE,
        p_fecha_fin IN DATE
    ) RETURN NUMBER;

    -- Horas promedio entre FECHA_INICIO y FECHA_FIN de órdenes ya cerradas/resueltas
    FUNCTION tiempo_medio_resolucion_horas (
        p_fecha_ini IN DATE DEFAULT NULL,
        p_fecha_fin IN DATE DEFAULT NULL
    ) RETURN NUMBER;

    -- Órdenes abiertas (NUEVO/EN_PROCESO/REABIERTO) por prioridad, para alertas de Home
    FUNCTION ordenes_criticas_abiertas RETURN NUMBER;

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


    FUNCTION tiempo_medio_resolucion_horas (
        p_fecha_ini IN DATE DEFAULT NULL,
        p_fecha_fin IN DATE DEFAULT NULL
    ) RETURN NUMBER IS
        v_promedio NUMBER;
    BEGIN
        SELECT ROUND(AVG(tiempo_real_horas), 2)
          INTO v_promedio
          FROM OP_ORDENES_TRABAJO
         WHERE tiempo_real_horas IS NOT NULL
           AND (p_fecha_ini IS NULL OR fecha_creacion >= p_fecha_ini)
           AND (p_fecha_fin IS NULL OR fecha_creacion <= p_fecha_fin);

        RETURN NVL(v_promedio, 0);
    END tiempo_medio_resolucion_horas;


    FUNCTION ordenes_criticas_abiertas RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM OP_ORDENES_TRABAJO
         WHERE estado IN ('NUEVO','EN_PROCESO','REABIERTO')
           AND prioridad = 'CRITICA';

        RETURN v_count;
    END ordenes_criticas_abiertas;

END PKG_REPORTING;
/

--------------------------------------------------------------------------------
-- 8. VISTAS DE KPI — pensadas para bindear directo en regiones APEX
--    (mismo patrón "tableName-like" que ya usa el resto de la app: una
--    interactiveReport o classicReport puede apuntar a una vista igual
--    que a una tabla, sin usar sqlQuery personalizado)
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_KPI_ORDENES_ESTADO AS
SELECT estado, COUNT(*) AS total
  FROM OP_ORDENES_TRABAJO
 GROUP BY estado;
COMMENT ON TABLE VW_KPI_ORDENES_ESTADO IS 'Conteo de órdenes de trabajo por estado, para gráfico de Home';

CREATE OR REPLACE VIEW VW_KPI_ACTIVOS_ESTADO AS
SELECT estado, COUNT(*) AS total
  FROM OP_ACTIVOS
 GROUP BY estado;
COMMENT ON TABLE VW_KPI_ACTIVOS_ESTADO IS 'Conteo de activos por estado, para gráfico de Home';

CREATE OR REPLACE VIEW VW_KPI_ORDENES_TECNICO AS
SELECT t.id_tecnico, t.nombre_completo, COUNT(o.id_orden) AS ordenes_abiertas
  FROM OP_TECNICOS t
  LEFT JOIN OP_ORDENES_TRABAJO o
         ON o.id_tecnico_asignado = t.id_tecnico
        AND o.estado IN ('NUEVO','EN_PROCESO','REABIERTO')
 WHERE t.activo = 'Y'
 GROUP BY t.id_tecnico, t.nombre_completo;
COMMENT ON TABLE VW_KPI_ORDENES_TECNICO IS 'Carga de trabajo actual por técnico, para el panel de cada técnico';

CREATE OR REPLACE VIEW VW_MANTENIMIENTOS_PROXIMOS AS
SELECT p.id_programacion, p.titulo, p.proxima_fecha, p.prioridad,
       a.nombre AS nombre_activo, t.nombre_completo AS tecnico_asignado
  FROM OP_MANTENIMIENTOS_PROGRAMADOS p
  JOIN OP_ACTIVOS a ON a.id_activo = p.id_activo
  LEFT JOIN OP_TECNICOS t ON t.id_tecnico = p.id_tecnico_asignado
 WHERE p.activo = 'Y'
 ORDER BY p.proxima_fecha;
COMMENT ON TABLE VW_MANTENIMIENTOS_PROXIMOS IS 'Vista lista para el calendario de mantenimientos (una fila por programación activa)';

--------------------------------------------------------------------------------
-- 9. Verificación — todos deben mostrar VALID
--------------------------------------------------------------------------------

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('OP_MANTENIMIENTOS_PROGRAMADOS','OP_ARTICULOS_KB',
                       'PKG_MANTENIMIENTOS','PKG_KB','PKG_REPORTING',
                       'VW_KPI_ORDENES_ESTADO','VW_KPI_ACTIVOS_ESTADO',
                       'VW_KPI_ORDENES_TECNICO','VW_MANTENIMIENTOS_PROXIMOS')
ORDER BY object_type, object_name;

--------------------------------------------------------------------------------
-- NOTA — automatizar generar_ordenes_vencidas()
-- Para que el calendario genere solo las órdenes vencidas todos los días,
-- programar un job (ejecutar una sola vez, fuera de este script):
--
-- BEGIN
--   DBMS_SCHEDULER.CREATE_JOB (
--     job_name        => 'JOB_GENERAR_MANTENIMIENTOS',
--     job_type        => 'PLSQL_BLOCK',
--     job_action      => 'DECLARE v NUMBER; BEGIN v := PKG_MANTENIMIENTOS.generar_ordenes_vencidas; END;',
--     start_date      => SYSTIMESTAMP,
--     repeat_interval => 'FREQ=DAILY; BYHOUR=6; BYMINUTE=0',
--     enabled         => TRUE
--   );
-- END;
-- /
--------------------------------------------------------------------------------