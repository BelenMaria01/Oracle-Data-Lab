--------------------------------------------------------------------------------
-- 01_TABLAS.sql
-- CMMS - Gestión de Mantenimiento de Activos (+ Portal de Soporte Externo)
--
-- Estructura COMPLETA consolidada. Reemplaza a todos los scripts incrementales
-- anteriores (04 a 10) — ya no hace falta correrlos por separado, esta es la
-- versión final de la base de datos, lista para crear desde cero.
--
-- Ejecutar sobre una base de datos vacía (o después de 00_RESET_TOTAL.sql).
-- Orden de este archivo: catálogos → activos → clientes → órdenes de trabajo →
-- inventario → auditoría/notificaciones.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. CATÁLOGOS BASE
--------------------------------------------------------------------------------

CREATE TABLE OP_UBICACIONES (
    ID_UBICACION    NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE          VARCHAR2(100)   NOT NULL,
    EDIFICIO        VARCHAR2(100),
    PLANTA          VARCHAR2(50),
    SALA            VARCHAR2(50),
    FECHA_ALTA      DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT UK_UBICACIONES_NOMBRE UNIQUE (NOMBRE)
);
COMMENT ON TABLE OP_UBICACIONES IS 'Ubicaciones físicas donde se localizan los activos (edificio/planta/sala)';

CREATE TABLE OP_TIPOS_ACTIVO (
    ID_TIPO_ACTIVO  NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE          VARCHAR2(100)   NOT NULL,
    DESCRIPCION     VARCHAR2(255),
    CONSTRAINT UK_TIPOS_ACTIVO_NOMBRE UNIQUE (NOMBRE)
);
COMMENT ON TABLE OP_TIPOS_ACTIVO IS 'Catálogo de tipos de activo IT: Servidor, PC, Portátil, Switch, Router, Impresora...';

CREATE TABLE OP_PROVEEDORES (
    ID_PROVEEDOR    NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE          VARCHAR2(150)   NOT NULL,
    CIF             VARCHAR2(20),
    TELEFONO        VARCHAR2(20),
    EMAIL           VARCHAR2(150),
    ACTIVO          VARCHAR2(1)     DEFAULT 'Y' NOT NULL CHECK (ACTIVO IN ('Y','N')),
    CONSTRAINT UK_PROVEEDORES_NOMBRE UNIQUE (NOMBRE)
);
COMMENT ON TABLE OP_PROVEEDORES IS 'Proveedores de equipos y repuestos';

CREATE TABLE OP_TECNICOS (
    ID_TECNICO      NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    USERNAME        VARCHAR2(100)   NOT NULL,
    NOMBRE_COMPLETO VARCHAR2(150)   NOT NULL,
    ESPECIALIDAD    VARCHAR2(100),
    EMAIL           VARCHAR2(150),
    ACTIVO          VARCHAR2(1)     DEFAULT 'Y' NOT NULL CHECK (ACTIVO IN ('Y','N')),
    FECHA_ALTA      DATE            DEFAULT SYSDATE NOT NULL,
    FECHA_BAJA      DATE,
    ROL             VARCHAR2(20)    DEFAULT 'TECNICO' NOT NULL CHECK (ROL IN ('ADMIN','TECNICO')),
    USUARIO_APEX    VARCHAR2(100),
    CONSTRAINT UQ_OP_TECNICOS_USERNAME UNIQUE (USERNAME)
);
COMMENT ON TABLE OP_TECNICOS IS 'Técnicos/empleados internos del sistema. USERNAME se vincula al usuario de sesión APEX';

--------------------------------------------------------------------------------
-- 2. ACTIVOS (inventario IT)
--------------------------------------------------------------------------------

CREATE TABLE OP_ACTIVOS (
    ID_ACTIVO               NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE                   VARCHAR2(150)  NOT NULL,
    ID_TIPO_ACTIVO           NUMBER         NOT NULL,
    MARCA                    VARCHAR2(100),
    MODELO                   VARCHAR2(100),
    NUM_SERIE                VARCHAR2(100),
    ID_UBICACION             NUMBER,
    IP_ASIGNADA              VARCHAR2(45),
    SISTEMA_OPERATIVO        VARCHAR2(100),
    ESTADO                   VARCHAR2(20)   DEFAULT 'ACTIVO' NOT NULL,
    FECHA_COMPRA             DATE,
    FECHA_FIN_GARANTIA       DATE,
    ID_TECNICO_RESPONSABLE   NUMBER,
    COSTE_ADQUISICION        NUMBER(10,2),
    ID_PROVEEDOR             NUMBER,
    FECHA_ALTA               DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT CK_OP_ACTIVOS_ESTADO CHECK (ESTADO IN ('ACTIVO','EN_REPARACION','BAJA','ALMACEN')),
    CONSTRAINT FK_ACTIVOS_TIPO      FOREIGN KEY (ID_TIPO_ACTIVO) REFERENCES OP_TIPOS_ACTIVO(ID_TIPO_ACTIVO),
    CONSTRAINT FK_ACTIVOS_UBIC      FOREIGN KEY (ID_UBICACION) REFERENCES OP_UBICACIONES(ID_UBICACION),
    CONSTRAINT FK_ACTIVOS_TECNICO   FOREIGN KEY (ID_TECNICO_RESPONSABLE) REFERENCES OP_TECNICOS(ID_TECNICO),
    CONSTRAINT FK_ACTIVOS_PROV      FOREIGN KEY (ID_PROVEEDOR) REFERENCES OP_PROVEEDORES(ID_PROVEEDOR)
);
COMMENT ON TABLE OP_ACTIVOS IS 'Inventario de activos IT: servidores, PCs, portátiles, red...';

--------------------------------------------------------------------------------
-- 3. CLIENTES (portal de soporte externo)
--------------------------------------------------------------------------------

CREATE TABLE OP_EMPRESAS_CLIENTE (
    ID_EMPRESA      NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE          VARCHAR2(200)   NOT NULL,
    CIF             VARCHAR2(20),
    DIRECCION       VARCHAR2(300),
    TELEFONO        VARCHAR2(30),
    EMAIL           VARCHAR2(150),
    ACTIVO          VARCHAR2(1)     DEFAULT 'Y' NOT NULL CHECK (ACTIVO IN ('Y','N')),
    FECHA_ALTA      DATE            DEFAULT SYSDATE NOT NULL
);
COMMENT ON TABLE OP_EMPRESAS_CLIENTE IS 'Empresas o comercios externos asociados, dueñas de sus propios clientes/usuarios';

CREATE TABLE OP_CLIENTES (
    ID_CLIENTE      NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE          VARCHAR2(150)   NOT NULL,
    EMAIL           VARCHAR2(150),
    TELEFONO        VARCHAR2(30),
    USUARIO_APEX    VARCHAR2(100),
    ID_EMPRESA      NUMBER,
    ROL             VARCHAR2(20)    DEFAULT 'CLIENTE' NOT NULL CHECK (ROL IN ('CLIENTE','CLIENTE_ADMIN')),
    ACTIVO          VARCHAR2(1)     DEFAULT 'Y' NOT NULL CHECK (ACTIVO IN ('Y','N')),
    FECHA_ALTA      DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT UQ_OP_CLIENTES_USUARIO UNIQUE (USUARIO_APEX),
    CONSTRAINT FK_CLIENTE_EMPRESA FOREIGN KEY (ID_EMPRESA) REFERENCES OP_EMPRESAS_CLIENTE(ID_EMPRESA)
);
COMMENT ON TABLE OP_CLIENTES IS 'Clientes/usuarios finales que pueden crear tickets (Órdenes de Trabajo) desde el portal';

--------------------------------------------------------------------------------
-- 4. ÓRDENES DE TRABAJO (= Tickets, estilo Mantis Bug Tracker)
--------------------------------------------------------------------------------

CREATE TABLE OP_ORDENES_TRABAJO (
    ID_ORDEN                NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TITULO                   VARCHAR2(200)  NOT NULL,
    DESCRIPCION               VARCHAR2(4000),
    PASOS_REPRODUCCION        VARCHAR2(4000),
    ID_ACTIVO                 NUMBER         NOT NULL,
    TIPO                       VARCHAR2(20)   DEFAULT 'CORRECTIVO' NOT NULL,
    PRIORIDAD                 VARCHAR2(10)   DEFAULT 'MEDIA' NOT NULL,
    SEVERIDAD                 VARCHAR2(10)   DEFAULT 'MENOR' NOT NULL,
    ESTADO                     VARCHAR2(20)   DEFAULT 'NUEVO' NOT NULL,
    ID_TECNICO_ASIGNADO       NUMBER,
    ID_SOLICITANTE             VARCHAR2(100),
    ID_CLIENTE                 NUMBER,
    FECHA_CREACION             DATE           DEFAULT SYSDATE NOT NULL,
    FECHA_ASIGNACION           DATE,
    FECHA_INICIO               DATE,
    FECHA_FIN                   DATE,
    TIEMPO_ESTIMADO_HORAS      NUMBER(6,2),
    TIEMPO_REAL_HORAS          NUMBER(6,2),
    COSTE_MANO_OBRA            NUMBER(10,2)   DEFAULT 0,
    COSTE_REPUESTOS            NUMBER(10,2)   DEFAULT 0,
    COSTE_TOTAL                NUMBER(10,2)   GENERATED ALWAYS AS (NVL(COSTE_MANO_OBRA,0) + NVL(COSTE_REPUESTOS,0)) VIRTUAL,
    OBSERVACIONES               VARCHAR2(4000),
    ADJUNTO_NOMBRE              VARCHAR2(255),
    ADJUNTO_MIME                VARCHAR2(100),
    ADJUNTO_CONTENIDO           BLOB,
    CONSTRAINT CK_OP_OT_TIPO       CHECK (TIPO IN ('CORRECTIVO','PREVENTIVO')),
    CONSTRAINT CK_OP_OT_PRIORIDAD  CHECK (PRIORIDAD IN ('BAJA','MEDIA','ALTA','CRITICA')),
    CONSTRAINT CK_OP_OT_SEVERIDAD  CHECK (SEVERIDAD IN ('TRIVIAL','MENOR','MAYOR','CRITICA')),
    CONSTRAINT CK_OP_OT_ESTADO     CHECK (ESTADO IN ('NUEVO','EN_PROCESO','RESUELTO','CERRADO','REABIERTO','CANCELADO')),
    CONSTRAINT FK_OT_ACTIVO         FOREIGN KEY (ID_ACTIVO) REFERENCES OP_ACTIVOS(ID_ACTIVO),
    CONSTRAINT FK_OT_TECNICO        FOREIGN KEY (ID_TECNICO_ASIGNADO) REFERENCES OP_TECNICOS(ID_TECNICO),
    CONSTRAINT FK_OT_CLIENTE        FOREIGN KEY (ID_CLIENTE) REFERENCES OP_CLIENTES(ID_CLIENTE)
);
COMMENT ON TABLE OP_ORDENES_TRABAJO IS 'Incidencias / órdenes de trabajo / tickets sobre activos. Un ticket de cliente ES una Orden de Trabajo (no hay tabla "tickets" separada)';

CREATE TABLE OP_ORDEN_HISTORIAL (
    ID_HISTORIAL     NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_ORDEN          NUMBER         NOT NULL,
    ESTADO_ANTERIOR    VARCHAR2(20),
    ESTADO_NUEVO       VARCHAR2(20)   NOT NULL,
    FECHA_CAMBIO       DATE           DEFAULT SYSDATE NOT NULL,
    USUARIO            VARCHAR2(100),
    CONSTRAINT FK_HIST_ORDEN FOREIGN KEY (ID_ORDEN) REFERENCES OP_ORDENES_TRABAJO(ID_ORDEN)
);
COMMENT ON TABLE OP_ORDEN_HISTORIAL IS 'Traza de cambios de estado de cada orden. Base para el KPI de tiempo medio de reparación';

CREATE TABLE OP_ORDEN_MENSAJES (
    ID_MENSAJE      NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_ORDEN        NUMBER          NOT NULL,
    TIPO_AUTOR      VARCHAR2(10)    NOT NULL CHECK (TIPO_AUTOR IN ('CLIENTE','TECNICO','ADMIN')),
    NOMBRE_AUTOR    VARCHAR2(150),
    MENSAJE         VARCHAR2(4000)  NOT NULL,
    ADJUNTO_URL     VARCHAR2(500),
    FECHA_MENSAJE   TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT FK_MSG_ORDEN FOREIGN KEY (ID_ORDEN) REFERENCES OP_ORDENES_TRABAJO(ID_ORDEN)
);
COMMENT ON TABLE OP_ORDEN_MENSAJES IS 'Hilo de mensajes/chat de un ticket entre cliente y técnico';

--------------------------------------------------------------------------------
-- 5. INVENTARIO / REPUESTOS
--------------------------------------------------------------------------------

CREATE TABLE OP_REPUESTOS (
    ID_REPUESTO       NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    CODIGO             VARCHAR2(50)   NOT NULL,
    NOMBRE             VARCHAR2(150)  NOT NULL,
    DESCRIPCION        VARCHAR2(500),
    CATEGORIA          VARCHAR2(100),
    STOCK_ACTUAL       NUMBER         DEFAULT 0 NOT NULL,
    STOCK_MINIMO       NUMBER         DEFAULT 0 NOT NULL,
    UNIDAD_MEDIDA      VARCHAR2(20)   DEFAULT 'UD',
    COSTE_UNITARIO     NUMBER(10,2),
    ID_PROVEEDOR       NUMBER,
    UBICACION_ALMACEN  VARCHAR2(100),
    CONSTRAINT UQ_OP_REPUESTOS_CODIGO UNIQUE (CODIGO),
    CONSTRAINT FK_REP_PROV FOREIGN KEY (ID_PROVEEDOR) REFERENCES OP_PROVEEDORES(ID_PROVEEDOR)
);
COMMENT ON TABLE OP_REPUESTOS IS 'Catálogo de repuestos disponibles en almacén';

CREATE TABLE OP_ORDEN_REPUESTOS (
    ID_ORDEN_REPUESTO         NUMBER        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_ORDEN                   NUMBER        NOT NULL,
    ID_REPUESTO                 NUMBER        NOT NULL,
    CANTIDAD                     NUMBER        NOT NULL,
    COSTE_UNITARIO_APLICADO     NUMBER(10,2),
    FECHA_USO                    DATE          DEFAULT SYSDATE,
    CONSTRAINT CK_OP_ORDREP_CANT CHECK (CANTIDAD > 0),
    CONSTRAINT FK_ORDREP_ORDEN    FOREIGN KEY (ID_ORDEN) REFERENCES OP_ORDENES_TRABAJO(ID_ORDEN),
    CONSTRAINT FK_ORDREP_REPUESTO FOREIGN KEY (ID_REPUESTO) REFERENCES OP_REPUESTOS(ID_REPUESTO)
);
COMMENT ON TABLE OP_ORDEN_REPUESTOS IS 'Repuestos consumidos en cada orden de trabajo (tabla puente N:M)';

CREATE TABLE OP_MOVIMIENTOS_STOCK (
    ID_MOVIMIENTO   NUMBER         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_REPUESTO      NUMBER         NOT NULL,
    TIPO_MOVIMIENTO   VARCHAR2(10)   NOT NULL,
    CANTIDAD          NUMBER         NOT NULL,
    ID_ORDEN          NUMBER,
    MOTIVO            VARCHAR2(255),
    FECHA             DATE           DEFAULT SYSDATE NOT NULL,
    USUARIO           VARCHAR2(100),
    CONSTRAINT CK_OP_MOV_TIPO CHECK (TIPO_MOVIMIENTO IN ('ENTRADA','SALIDA')),
    CONSTRAINT CK_OP_MOV_CANT CHECK (CANTIDAD > 0),
    CONSTRAINT FK_MOV_REPUESTO FOREIGN KEY (ID_REPUESTO) REFERENCES OP_REPUESTOS(ID_REPUESTO),
    CONSTRAINT FK_MOV_ORDEN    FOREIGN KEY (ID_ORDEN) REFERENCES OP_ORDENES_TRABAJO(ID_ORDEN)
);
COMMENT ON TABLE OP_MOVIMIENTOS_STOCK IS 'Histórico completo de entradas y salidas de almacén (compras, ajustes, consumo)';

--------------------------------------------------------------------------------
-- 6. AUDITORÍA Y NOTIFICACIONES
--------------------------------------------------------------------------------

CREATE TABLE OP_AUDITORIA (
    ID_AUDITORIA    NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NOMBRE_TABLA    VARCHAR2(50)    NOT NULL,
    ID_REGISTRO     NUMBER,
    ACCION          VARCHAR2(20)    NOT NULL,
    USUARIO         VARCHAR2(100),
    FECHA_EVENTO    DATE            DEFAULT SYSDATE NOT NULL,
    DETALLE         VARCHAR2(4000)
);
COMMENT ON TABLE OP_AUDITORIA IS 'Registro genérico de auditoría de cambios en tablas operativas';
-- Nota: sin CHECK sobre ACCION — en la práctica se usan valores como
-- 'INSERT'/'UPDATE'/'DELETE' y también 'ALTA'/'CAMBIO_ESTADO' (PKG_ACTIVOS),
-- dejar abierto evita futuros ORA-02290 al añadir nuevas acciones.

CREATE TABLE OP_NOTIFICACIONES (
    ID_NOTIFICACION     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TIPO                 VARCHAR2(30)  NOT NULL,
    MENSAJE              VARCHAR2(500) NOT NULL,
    ID_REGISTRO          NUMBER,
    NOMBRE_TABLA         VARCHAR2(60),
    LEIDA                CHAR(1)       DEFAULT 'N' NOT NULL,
    FECHA_CREACION       DATE          DEFAULT SYSDATE NOT NULL,
    ID_TECNICO_DESTINO   NUMBER,
    CONSTRAINT CK_NOTIF_LEIDA CHECK (LEIDA IN ('S','N')),
    CONSTRAINT FK_NOTIF_TECNICO FOREIGN KEY (ID_TECNICO_DESTINO) REFERENCES OP_TECNICOS(ID_TECNICO)
);
COMMENT ON TABLE OP_NOTIFICACIONES IS 'Notificaciones internas (stock bajo, orden asignada...)';

--------------------------------------------------------------------------------
-- 7. ÍNDICES SOBRE CLAVES FORÁNEAS
-- Oracle no crea índice automático sobre FK; se crean explícitamente
-- para evitar bloqueos y mejorar el rendimiento de los joins.
--------------------------------------------------------------------------------

CREATE INDEX IX_ACTIVOS_TIPO      ON OP_ACTIVOS(ID_TIPO_ACTIVO);
CREATE INDEX IX_ACTIVOS_UBIC      ON OP_ACTIVOS(ID_UBICACION);
CREATE INDEX IX_ACTIVOS_TECNICO   ON OP_ACTIVOS(ID_TECNICO_RESPONSABLE);
CREATE INDEX IX_ACTIVOS_PROV      ON OP_ACTIVOS(ID_PROVEEDOR);

CREATE INDEX IX_CLIENTES_EMPRESA  ON OP_CLIENTES(ID_EMPRESA);

CREATE INDEX IX_OT_ACTIVO         ON OP_ORDENES_TRABAJO(ID_ACTIVO);
CREATE INDEX IX_OT_TECNICO        ON OP_ORDENES_TRABAJO(ID_TECNICO_ASIGNADO);
CREATE INDEX IX_OT_CLIENTE        ON OP_ORDENES_TRABAJO(ID_CLIENTE);
CREATE INDEX IX_OT_ESTADO         ON OP_ORDENES_TRABAJO(ESTADO);

CREATE INDEX IX_HIST_ORDEN        ON OP_ORDEN_HISTORIAL(ID_ORDEN);
CREATE INDEX IX_MSG_ORDEN         ON OP_ORDEN_MENSAJES(ID_ORDEN);

CREATE INDEX IX_REP_PROV          ON OP_REPUESTOS(ID_PROVEEDOR);

CREATE INDEX IX_ORDREP_ORDEN      ON OP_ORDEN_REPUESTOS(ID_ORDEN);
CREATE INDEX IX_ORDREP_REPUESTO   ON OP_ORDEN_REPUESTOS(ID_REPUESTO);

CREATE INDEX IX_MOV_REPUESTO      ON OP_MOVIMIENTOS_STOCK(ID_REPUESTO);
CREATE INDEX IX_MOV_ORDEN         ON OP_MOVIMIENTOS_STOCK(ID_ORDEN);

CREATE INDEX IX_AUD_TABLA_REG     ON OP_AUDITORIA(NOMBRE_TABLA, ID_REGISTRO);

CREATE INDEX IX_NOTIF_TECNICO     ON OP_NOTIFICACIONES(ID_TECNICO_DESTINO);
CREATE INDEX IX_NOTIF_LEIDA       ON OP_NOTIFICACIONES(LEIDA);

--------------------------------------------------------------------------------
-- 8. Verificación
--------------------------------------------------------------------------------

SELECT table_name FROM user_tables WHERE table_name LIKE 'OP\_%' ESCAPE '\' ORDER BY table_name;