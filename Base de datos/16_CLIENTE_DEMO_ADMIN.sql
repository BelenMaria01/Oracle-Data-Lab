--------------------------------------------------------------------------------
-- 16_CLIENTE_DEMO_ADMIN.sql
-- CMMS - Gestión de Mantenimiento de Activos
--
-- Sube al usuario de prueba cliente_demo (creado en 15_CREAR_USUARIOS_PRUEBA.sql
-- con rol 'CLIENTE') a 'CLIENTE_ADMIN', para poder ver y probar la página 29
-- "Tickets Empresa" (protegida por el authorization scheme @es-cliente-admin,
-- que exige G_ROL_USUARIO = 'CLIENTE_ADMIN').
--
-- No crea usuarios nuevos ni toca la cuenta de login de APEX: cliente_demo
-- sigue siendo el mismo login (cliente_demo / Cliente#2026), solo cambia su
-- rol de negocio dentro de OP_CLIENTES.
--------------------------------------------------------------------------------

UPDATE OP_CLIENTES
   SET rol = 'CLIENTE_ADMIN'
 WHERE usuario_apex = 'cliente_demo';

COMMIT;

--------------------------------------------------------------------------------
-- Verificación
--------------------------------------------------------------------------------
SELECT usuario_apex, nombre, rol
  FROM OP_CLIENTES
 WHERE usuario_apex = 'cliente_demo';
