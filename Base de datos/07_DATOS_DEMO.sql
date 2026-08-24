--------------------------------------------------------------------------------
-- 07_DATOS_DEMO.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Datos de ejemplo para que la app no se vea vacía mientras probás.
-- Usa subconsultas por NOMBRE/USERNAME (no IDs fijos), así que funciona
-- sin importar qué hayas cargado ya a mano desde la UI.
--
-- Se puede correr una sola vez sobre una base "limpia" de estas tablas.
-- Si ya tenés algún Tipo de Activo / Ubicación / Proveedor / Técnico con el
-- mismo NOMBRE / USERNAME, esa fila puntual va a fallar por la restricción
-- UNIQUE — no pasa nada, seguí con el resto.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. Catálogos
--------------------------------------------------------------------------------

INSERT INTO OP_TIPOS_ACTIVO (NOMBRE, DESCRIPCION) VALUES ('Servidor', 'Servidores físicos y virtuales de datacenter');
INSERT INTO OP_TIPOS_ACTIVO (NOMBRE, DESCRIPCION) VALUES ('PC de Escritorio', 'Equipos de escritorio para puestos de trabajo');
INSERT INTO OP_TIPOS_ACTIVO (NOMBRE, DESCRIPCION) VALUES ('Portátil', 'Equipos portátiles de uso general');
INSERT INTO OP_TIPOS_ACTIVO (NOMBRE, DESCRIPCION) VALUES ('Switch', 'Equipos de red - conmutadores');
INSERT INTO OP_TIPOS_ACTIVO (NOMBRE, DESCRIPCION) VALUES ('Impresora', 'Impresoras y multifunción de oficina');

INSERT INTO OP_UBICACIONES (NOMBRE, EDIFICIO, PLANTA, SALA) VALUES ('Oficina Central - Planta 1', 'Edificio A', 'Planta 1', 'Sala 101');
INSERT INTO OP_UBICACIONES (NOMBRE, EDIFICIO, PLANTA, SALA) VALUES ('Oficina Central - Planta 2', 'Edificio A', 'Planta 2', 'Sala 204');
INSERT INTO OP_UBICACIONES (NOMBRE, EDIFICIO, PLANTA, SALA) VALUES ('Sala de Servidores', 'Edificio A', 'Sótano', 'CPD-01');
INSERT INTO OP_UBICACIONES (NOMBRE, EDIFICIO, PLANTA, SALA) VALUES ('Almacén IT', 'Edificio B', 'Planta Baja', 'Almacén');

INSERT INTO OP_PROVEEDORES (NOMBRE, CIF, TELEFONO, EMAIL) VALUES ('Tecnología Ibérica S.L.', 'B12345678', '+34 912 345 678', 'contacto@tecnologiaiberica.es');
INSERT INTO OP_PROVEEDORES (NOMBRE, CIF, TELEFONO, EMAIL) VALUES ('Dell Technologies', 'B23456789', '+34 913 456 789', 'ventas@dell.es');
INSERT INTO OP_PROVEEDORES (NOMBRE, CIF, TELEFONO, EMAIL) VALUES ('HP Enterprise', 'B34567890', '+34 914 567 890', 'contacto@hpe.es');
INSERT INTO OP_PROVEEDORES (NOMBRE, CIF, TELEFONO, EMAIL) VALUES ('Cisco Systems España', 'B45678901', '+34 915 678 901', 'info@cisco.es');

--------------------------------------------------------------------------------
-- 2. Técnicos
-- El primero está vinculado a USUARIO_APEX = 'CMMS_ADMIN' para que el
-- appProcess de resolución de rol lo reconozca automáticamente al iniciar
-- sesión como cmms_admin. Cambiá el valor si tu usuario de login es otro.
--------------------------------------------------------------------------------

INSERT INTO OP_TECNICOS (USERNAME, NOMBRE_COMPLETO, ESPECIALIDAD, EMAIL, ROL, USUARIO_APEX)
VALUES ('admin', 'Administrador CMMS', 'Administración de Sistemas', 'admin@empresa.com', 'ADMIN', 'CMMS_ADMIN');

INSERT INTO OP_TECNICOS (USERNAME, NOMBRE_COMPLETO, ESPECIALIDAD, EMAIL, ROL)
VALUES ('jgarcia', 'Juan García', 'Redes y Comunicaciones', 'jgarcia@empresa.com', 'TECNICO');

INSERT INTO OP_TECNICOS (USERNAME, NOMBRE_COMPLETO, ESPECIALIDAD, EMAIL, ROL)
VALUES ('mlopez', 'María López', 'Soporte de Hardware', 'mlopez@empresa.com', 'TECNICO');

--------------------------------------------------------------------------------
-- 3. Inventario IT — 6 equipos de ejemplo con distintos estados
--------------------------------------------------------------------------------

INSERT INTO OP_ACTIVOS (
    NOMBRE, ID_TIPO_ACTIVO, MARCA, MODELO, NUM_SERIE, ID_UBICACION,
    IP_ASIGNADA, SISTEMA_OPERATIVO, ESTADO, FECHA_COMPRA, FECHA_FIN_GARANTIA,
    ID_TECNICO_RESPONSABLE, COSTE_ADQUISICION, ID_PROVEEDOR
) VALUES (
    'SRV-DB-01',
    (SELECT id_tipo_activo FROM OP_TIPOS_ACTIVO WHERE nombre = 'Servidor'),
    'Dell', 'PowerEdge R740', 'SN-DL7401',
    (SELECT id_ubicacion FROM OP_UBICACIONES WHERE nombre = 'Sala de Servidores'),
    '10.0.1.10', 'Windows Server 2022', 'ACTIVO',
    DATE '2023-03-15', DATE '2026-03-15',
    (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'admin'),
    4500.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Dell Technologies')
);

INSERT INTO OP_ACTIVOS (
    NOMBRE, ID_TIPO_ACTIVO, MARCA, MODELO, NUM_SERIE, ID_UBICACION,
    IP_ASIGNADA, SISTEMA_OPERATIVO, ESTADO, FECHA_COMPRA, FECHA_FIN_GARANTIA,
    ID_TECNICO_RESPONSABLE, COSTE_ADQUISICION, ID_PROVEEDOR
) VALUES (
    'SW-CORE-02',
    (SELECT id_tipo_activo FROM OP_TIPOS_ACTIVO WHERE nombre = 'Switch'),
    'Cisco', 'Catalyst 9200', 'FOC1234XYZ',
    (SELECT id_ubicacion FROM OP_UBICACIONES WHERE nombre = 'Sala de Servidores'),
    '10.0.1.1', 'IOS XE 17.6', 'ACTIVO',
    DATE '2022-11-01', DATE '2025-11-01',
    (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia'),
    1800.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Cisco Systems España')
);

INSERT INTO OP_ACTIVOS (
    NOMBRE, ID_TIPO_ACTIVO, MARCA, MODELO, NUM_SERIE, ID_UBICACION,
    IP_ASIGNADA, SISTEMA_OPERATIVO, ESTADO, FECHA_COMPRA, FECHA_FIN_GARANTIA,
    ID_TECNICO_RESPONSABLE, COSTE_ADQUISICION, ID_PROVEEDOR
) VALUES (
    'PC-RRHH-05',
    (SELECT id_tipo_activo FROM OP_TIPOS_ACTIVO WHERE nombre = 'PC de Escritorio'),
    'HP', 'EliteDesk 800 G9', 'HP800G9-0005',
    (SELECT id_ubicacion FROM OP_UBICACIONES WHERE nombre = 'Oficina Central - Planta 1'),
    '10.0.2.15', 'Windows 11 Pro', 'ACTIVO',
    DATE '2024-01-20', DATE '2027-01-20',
    (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'mlopez'),
    950.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'HP Enterprise')
);

INSERT INTO OP_ACTIVOS (
    NOMBRE, ID_TIPO_ACTIVO, MARCA, MODELO, NUM_SERIE, ID_UBICACION,
    IP_ASIGNADA, SISTEMA_OPERATIVO, ESTADO, FECHA_COMPRA, FECHA_FIN_GARANTIA,
    ID_TECNICO_RESPONSABLE, COSTE_ADQUISICION, ID_PROVEEDOR
) VALUES (
    'LAP-VENTAS-12',
    (SELECT id_tipo_activo FROM OP_TIPOS_ACTIVO WHERE nombre = 'Portátil'),
    'Dell', 'Latitude 5440', 'DL5440-0012',
    (SELECT id_ubicacion FROM OP_UBICACIONES WHERE nombre = 'Oficina Central - Planta 2'),
    '10.0.2.40', 'Windows 11 Pro', 'EN_REPARACION',
    DATE '2023-06-10', DATE '2026-06-10',
    (SELECT id_tecnico FROM OP_TECNICOS WHERE username = 'jgarcia'),
    1250.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'Dell Technologies')
);

INSERT INTO OP_ACTIVOS (
    NOMBRE, ID_TIPO_ACTIVO, MARCA, MODELO, NUM_SERIE, ID_UBICACION,
    IP_ASIGNADA, SISTEMA_OPERATIVO, ESTADO, FECHA_COMPRA, FECHA_FIN_GARANTIA,
    ID_TECNICO_RESPONSABLE, COSTE_ADQUISICION, ID_PROVEEDOR
) VALUES (
    'IMP-PLANTA1-02',
    (SELECT id_tipo_activo FROM OP_TIPOS_ACTIVO WHERE nombre = 'Impresora'),
    'HP', 'LaserJet Enterprise M507', 'HPM507-0002',
    (SELECT id_ubicacion FROM OP_UBICACIONES WHERE nombre = 'Oficina Central - Planta 1'),
    '10.0.2.60', NULL, 'ACTIVO',
    DATE '2022-05-05', DATE '2025-05-05',
    NULL,
    650.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'HP Enterprise')
);

INSERT INTO OP_ACTIVOS (
    NOMBRE, ID_TIPO_ACTIVO, MARCA, MODELO, NUM_SERIE, ID_UBICACION,
    IP_ASIGNADA, SISTEMA_OPERATIVO, ESTADO, FECHA_COMPRA, FECHA_FIN_GARANTIA,
    ID_TECNICO_RESPONSABLE, COSTE_ADQUISICION, ID_PROVEEDOR
) VALUES (
    'PC-ANTIGUO-01',
    (SELECT id_tipo_activo FROM OP_TIPOS_ACTIVO WHERE nombre = 'PC de Escritorio'),
    'HP', 'ProDesk 400 G6', 'HP400G6-0001',
    (SELECT id_ubicacion FROM OP_UBICACIONES WHERE nombre = 'Almacén IT'),
    NULL, NULL, 'ALMACEN',
    DATE '2019-02-14', DATE '2022-02-14',
    NULL,
    600.00,
    (SELECT id_proveedor FROM OP_PROVEEDORES WHERE nombre = 'HP Enterprise')
);

COMMIT;

--------------------------------------------------------------------------------
-- 4. Verificación
--------------------------------------------------------------------------------

SELECT 'OP_TIPOS_ACTIVO' tabla, COUNT(*) filas FROM OP_TIPOS_ACTIVO
UNION ALL SELECT 'OP_UBICACIONES', COUNT(*) FROM OP_UBICACIONES
UNION ALL SELECT 'OP_PROVEEDORES', COUNT(*) FROM OP_PROVEEDORES
UNION ALL SELECT 'OP_TECNICOS', COUNT(*) FROM OP_TECNICOS
UNION ALL SELECT 'OP_ACTIVOS', COUNT(*) FROM OP_ACTIVOS;