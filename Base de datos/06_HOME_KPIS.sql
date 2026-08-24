--------------------------------------------------------------------------------
-- 06_HOME_KPIS.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. Ejecutar sobre la base de datos ya en uso.
-- Agrega las 2 vistas de KPI que faltaban para el dashboard de Home
-- (las otras 4 ya se crearon en 04_CALENDARIO_KB.sql).
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW VW_KPI_TECNICOS_ACTIVO AS
SELECT activo, COUNT(*) AS total
  FROM OP_TECNICOS
 GROUP BY activo;
COMMENT ON TABLE VW_KPI_TECNICOS_ACTIVO IS 'Conteo de técnicos activos/inactivos, para tarjeta KPI de Home';

CREATE OR REPLACE VIEW VW_KPI_REPUESTOS_BAJO_MINIMO AS
SELECT id_repuesto, codigo, nombre, stock_actual, stock_minimo
  FROM OP_REPUESTOS
 WHERE stock_actual < stock_minimo;
COMMENT ON TABLE VW_KPI_REPUESTOS_BAJO_MINIMO IS 'Repuestos por debajo del stock mínimo, para la alerta de Home';

-- Verificación — debe mostrar VALID
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('VW_KPI_TECNICOS_ACTIVO','VW_KPI_REPUESTOS_BAJO_MINIMO')
ORDER BY object_name;