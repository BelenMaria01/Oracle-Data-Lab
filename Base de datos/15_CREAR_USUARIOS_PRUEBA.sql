--------------------------------------------------------------------------------
-- 15_CREAR_USUARIOS_PRUEBA.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- IMPORTANTE: correr esto desde SQL Workshop → SQL Commands dentro de APEX
-- (no desde un cliente SQL externo). APEX_UTIL.CREATE_USER necesita el
-- contexto del workspace activo, que SQL Commands ya trae puesto. Si lo
-- corrés desde otro lado y da error de "workspace no identificado", avisame
-- y lo resolvemos con APEX_UTIL.SET_WORKSPACE.
--
-- Crea 2 cuentas de login reales de APEX:
--   tecnico_demo / Tecnico#2026   -> vinculada al técnico "jgarcia" (Juan García)
--   cliente_demo / Cliente#2026   -> cliente nuevo, empresa "Cliente Demo S.L."
--
-- Cambiá las contraseñas después del primer login si vas a dejar esto
-- corriendo más tiempo.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 1. Cuenta de APEX para el técnico
--------------------------------------------------------------------------------
BEGIN
    APEX_UTIL.CREATE_USER(
        p_user_name       => 'tecnico_demo',
        p_web_password    => 'Tecnico#2026',
        p_developer_privs => 'NONE',
        p_email_address   => 'tecnico.demo@empresa-ejemplo.com'
    );
EXCEPTION
    WHEN OTHERS THEN
        IF INSTR(SQLERRM, 'already exists') > 0 OR INSTR(SQLERRM, 'ya existe') > 0 THEN
            APEX_UTIL.EDIT_USER(
                p_user_id      => APEX_UTIL.GET_USER_ID('TECNICO_DEMO'),
                p_user_name    => 'tecnico_demo',
                p_web_password => 'Tecnico#2026'
            );
        ELSE
            RAISE;
        END IF;
END;
/

UPDATE OP_TECNICOS
   SET usuario_apex = 'tecnico_demo'
 WHERE username = 'jgarcia';

--------------------------------------------------------------------------------
-- 2. Cuenta de APEX para el cliente (+ empresa y registro de cliente)
--------------------------------------------------------------------------------
BEGIN
    APEX_UTIL.CREATE_USER(
        p_user_name       => 'cliente_demo',
        p_web_password    => 'Cliente#2026',
        p_developer_privs => 'NONE',
        p_email_address   => 'cliente.demo@empresa-cliente.com'
    );
EXCEPTION
    WHEN OTHERS THEN
        IF INSTR(SQLERRM, 'already exists') > 0 OR INSTR(SQLERRM, 'ya existe') > 0 THEN
            APEX_UTIL.EDIT_USER(
                p_user_id      => APEX_UTIL.GET_USER_ID('CLIENTE_DEMO'),
                p_user_name    => 'cliente_demo',
                p_web_password => 'Cliente#2026'
            );
        ELSE
            RAISE;
        END IF;
END;
/

DECLARE
    v_id_empresa NUMBER;
BEGIN
    INSERT INTO OP_EMPRESAS_CLIENTE (nombre, cif, email)
    VALUES ('Cliente Demo S.L.', 'B99999999', 'contacto@empresa-cliente.com')
    RETURNING id_empresa INTO v_id_empresa;

    INSERT INTO OP_CLIENTES (nombre, email, usuario_apex, id_empresa, rol)
    VALUES ('Cliente de Prueba', 'cliente.demo@empresa-cliente.com', 'cliente_demo', v_id_empresa, 'CLIENTE');
END;
/

COMMIT;

--------------------------------------------------------------------------------
-- Verificación
--------------------------------------------------------------------------------
SELECT 'tecnico_demo' usuario, 'Tecnico#2026' clave, username tecnico_vinculado
  FROM OP_TECNICOS WHERE usuario_apex = 'tecnico_demo'
UNION ALL
SELECT 'cliente_demo', 'Cliente#2026', nombre
  FROM OP_CLIENTES WHERE usuario_apex = 'cliente_demo';
