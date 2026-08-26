--------------------------------------------------------------------------------
-- 19_ALTER_ACTIVOS_EMPRESA.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Requiere que ya se hayan corrido:
--   01_TABLAS.sql, 07_DATOS_DEMO.sql, 15_CREAR_USUARIOS_PRUEBA.sql
--
-- Motivo: hasta ahora OP_ACTIVOS no tenía ninguna relación con
-- OP_EMPRESAS_CLIENTE. Los tickets de un cliente simplemente referenciaban
-- el mismo inventario interno de equipos (SRV-DB-01, PC-RRHH-05...), sin que
-- existiera el concepto de "este equipo es de tal empresa cliente". Esto
-- impedía construir una página "Mis Activos" real para el portal de cliente.
--
-- Columna nueva, NULLABLE, no rompe nada de lo ya existente: un activo con
-- ID_EMPRESA = NULL sigue siendo un activo puramente interno (servidores,
-- switches, etc. que no pertenecen a ningún cliente externo). Solo los
-- activos que sí son de un cliente externo llevan el ID_EMPRESA seteado.
--------------------------------------------------------------------------------

ALTER TABLE OP_ACTIVOS ADD (
    ID_EMPRESA NUMBER
);
ALTER TABLE OP_ACTIVOS ADD CONSTRAINT FK_ACTIVOS_EMPRESA
    FOREIGN KEY (ID_EMPRESA) REFERENCES OP_EMPRESAS_CLIENTE(ID_EMPRESA);
COMMENT ON COLUMN OP_ACTIVOS.ID_EMPRESA IS
    'NULL si el activo es puramente interno; con valor si pertenece a una empresa cliente externa (ver portal de cliente, página Mis Activos)';

--------------------------------------------------------------------------------
-- Datos demo: los 2 equipos que ya aparecen en los tickets de cliente_demo
-- / Ana Torres ("Cliente Demo S.L.") pasan a pertenecer a esa empresa.
--------------------------------------------------------------------------------

UPDATE OP_ACTIVOS
   SET ID_EMPRESA = (SELECT id_empresa FROM OP_EMPRESAS_CLIENTE WHERE nombre = 'Cliente Demo S.L.')
 WHERE nombre IN ('SRV-DB-01', 'PC-RRHH-05');

COMMIT;

--------------------------------------------------------------------------------
-- Verificación
--------------------------------------------------------------------------------
SELECT a.nombre, e.nombre AS empresa
  FROM OP_ACTIVOS a
  LEFT JOIN OP_EMPRESAS_CLIENTE e ON e.id_empresa = a.id_empresa
 ORDER BY e.nombre NULLS LAST, a.nombre;
