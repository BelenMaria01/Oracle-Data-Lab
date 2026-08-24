--------------------------------------------------------------------------------
-- 08_FIX_LOGIN_DUPLICADOS.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- URGENTE: corrige el ORA-01422 al iniciar sesión.
-- Causa: OP_TECNICOS nunca tuvo restricción UNIQUE sobre USUARIO_APEX
-- (a diferencia de OP_CLIENTES, que sí la tenía desde 01_TABLAS.sql). Al
-- haber más de un técnico con el mismo USUARIO_APEX, el SELECT INTO que
-- resuelve el rol al iniciar sesión encuentra más de una fila y explota.
--
-- Ejecutar sobre la base de datos ya en uso (no requiere reset).
--------------------------------------------------------------------------------

-- 1. Diagnóstico — mostrá esto antes de corregir, para ver qué se va a tocar
SELECT id_tecnico, username, nombre_completo, usuario_apex
  FROM OP_TECNICOS
 WHERE usuario_apex IS NOT NULL
 ORDER BY UPPER(usuario_apex), id_tecnico;

-- 2. Deduplicar: para cada USUARIO_APEX repetido, conserva el vínculo solo
--    en el técnico creado primero (ID más bajo) y limpia el resto a NULL.
--    Genérico: corrige cualquier duplicado que haya, no solo 'CMMS_ADMIN'.
UPDATE OP_TECNICOS
   SET usuario_apex = NULL
 WHERE usuario_apex IS NOT NULL
   AND id_tecnico NOT IN (
        SELECT MIN(id_tecnico)
          FROM OP_TECNICOS
         WHERE usuario_apex IS NOT NULL
         GROUP BY UPPER(usuario_apex)
   );

COMMIT;

-- 3. Restricción UNIQUE que faltaba (para que esto no pueda volver a pasar)
ALTER TABLE OP_TECNICOS ADD CONSTRAINT UQ_OP_TECNICOS_USUARIO_APEX UNIQUE (usuario_apex);

-- 4. Verificación — no debería haber ningún duplicado, y la constraint debe existir
SELECT UPPER(usuario_apex) usuario, COUNT(*) repetidos
  FROM OP_TECNICOS
 WHERE usuario_apex IS NOT NULL
 GROUP BY UPPER(usuario_apex)
HAVING COUNT(*) > 1;

SELECT constraint_name, status
  FROM user_constraints
 WHERE constraint_name = 'UQ_OP_TECNICOS_USUARIO_APEX';