--------------------------------------------------------------------------------
-- 00_RESET_TOTAL.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- ⚠️ BORRA TODO. Solo para volver a empezar de cero.
-- Elimina todas las tablas OP_*, todas las vistas VW_*, todos los paquetes
-- PKG_*, y sus datos. No hace falta borrar triggers a mano: se eliminan
-- solos junto con su tabla.
--------------------------------------------------------------------------------

-- 1. Borrar todas las tablas del proyecto (CASCADE CONSTRAINTS resuelve
--    automáticamente las dependencias por FK, sin importar el orden)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'OP\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/

-- 2. Borrar todas las vistas del proyecto
--    (DROP TABLE ... CASCADE CONSTRAINTS no elimina las vistas que dependían
--    de esas tablas, solo las deja inválidas — hay que borrarlas aparte)
BEGIN
    FOR v IN (SELECT view_name FROM user_views WHERE view_name LIKE 'VW\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
    END LOOP;
END;
/

-- 3. Borrar todos los paquetes del proyecto
BEGIN
    FOR p IN (SELECT object_name FROM user_objects
              WHERE object_type = 'PACKAGE' AND object_name LIKE 'PKG\_%' ESCAPE '\') LOOP
        EXECUTE IMMEDIATE 'DROP PACKAGE ' || p.object_name;
    END LOOP;
END;
/

-- 4. Verificación — debería devolver 0 filas en las tres
SELECT table_name FROM user_tables WHERE table_name LIKE 'OP\_%' ESCAPE '\';
SELECT view_name FROM user_views WHERE view_name LIKE 'VW\_%' ESCAPE '\';
SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE' AND object_name LIKE 'PKG\_%' ESCAPE '\';