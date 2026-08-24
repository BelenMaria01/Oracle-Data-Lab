--------------------------------------------------------------------------------
-- 04_ALTA_ADMIN.sql
-- Da de alta (o actualiza) el primer usuario Admin para poder entrar a la app.
--------------------------------------------------------------------------------

-- 1) Antes que nada, mirá con qué usuario estás logueado en APEX ahora mismo:
SELECT SYS_CONTEXT('APEX$SESSION', 'APP_USER') AS mi_usuario_apex FROM DUAL;

-- Copiá el valor que te devuelve esa consulta y usalo abajo en 'TU_USUARIO_AQUI'.

--------------------------------------------------------------------------------
-- 2) Alta / actualización del admin (sirve tanto si OP_TECNICOS está vacía
--    como si ya tenía datos de antes)
--------------------------------------------------------------------------------

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM OP_TECNICOS
    WHERE UPPER(usuario_apex) = UPPER('cmms_admin');

    IF v_count = 0 THEN
        -- No existe todavía: lo creamos
        INSERT INTO OP_TECNICOS (username, nombre_completo, rol, usuario_apex, activo)
        VALUES ('cmms_admin', 'Administrador', 'ADMIN', 'cmms_admin', 'Y');
    ELSE
        -- Ya existe: solo nos aseguramos de que sea ADMIN
        UPDATE OP_TECNICOS
        SET rol = 'ADMIN'
        WHERE UPPER(usuario_apex) = UPPER('cmms_admin');
    END IF;

    COMMIT;
END;
/

-- 3) Verificación
SELECT id_tecnico, username, nombre_completo, rol, usuario_apex
FROM OP_TECNICOS
WHERE UPPER(usuario_apex) = UPPER('cmms_admin');