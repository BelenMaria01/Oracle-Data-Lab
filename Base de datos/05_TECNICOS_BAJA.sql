--------------------------------------------------------------------------------
-- 05_TECNICOS_BAJA.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Migración incremental. NO reemplaza a los scripts anteriores, los
-- complementa. Ejecutar sobre la base de datos ya en uso (no requiere reset).
--
-- Sella/limpia automáticamente OP_TECNICOS.FECHA_BAJA cuando cambia ACTIVO,
-- para que la página de Técnicos (APEX) no tenga que manejar esa fecha:
-- el formulario solo cambia ACTIVO ('Y'/'N') y el trigger hace el resto.
--------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER TRG_OP_TECNICOS_BAJA
BEFORE UPDATE OF activo ON OP_TECNICOS
FOR EACH ROW
BEGIN
    IF :NEW.activo = 'N' AND :OLD.activo = 'Y' THEN
        :NEW.fecha_baja := SYSDATE;
    ELSIF :NEW.activo = 'Y' AND :OLD.activo = 'N' THEN
        :NEW.fecha_baja := NULL;
    END IF;
END;
/

-- Verificación — debe mostrar VALID
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'TRG_OP_TECNICOS_BAJA';