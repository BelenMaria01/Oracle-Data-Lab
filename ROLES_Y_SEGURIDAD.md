# Roles y Seguridad

## Los 3 roles

| Rol | Quién es | Qué ve |
|---|---|---|
| **Admin** | Administrador del sistema | Todo — inventario, técnicos, órdenes, informes, y en el futuro la gestión de usuarios |
| **Técnico** | Empleado interno de mantenimiento | Todo lo operativo (igual que Admin), excepto lo exclusivo de administración |
| **Cliente** | Usuario externo (u otra área de la empresa) | Solo su propio portal de tickets — nada del inventario ni de la gestión interna |

Un cuarto sub-rol, **Cliente Admin**, existe dentro de una empresa cliente para en el futuro poder gestionar los usuarios de su propia empresa (invitar/dar de baja usuarios de su organización).

## Cómo se resuelve el rol al iniciar sesión

Al loguearse, un proceso de aplicación (`appProcess`, ejecutado `afterAuthentication`) hace lo siguiente:

```
1. Busca UPPER(:APP_USER) en OP_TECNICOS.usuario_apex
   → si lo encuentra: G_ROL_USUARIO = su rol (ADMIN o TECNICO)
                       G_ID_TECNICO_ACTUAL = su id

2. Si no lo encontró en el paso 1, busca en OP_CLIENTES.usuario_apex
   → si lo encuentra: G_ROL_USUARIO = su rol (CLIENTE o CLIENTE_ADMIN)
                       G_ID_CLIENTE_ACTUAL = su id

3. Si no aparece en ninguna de las dos tablas:
   G_ROL_USUARIO queda NULL → no tiene acceso a nada protegido
```

Estas variables (`G_ROL_USUARIO`, `G_ID_TECNICO_ACTUAL`, `G_ID_CLIENTE_ACTUAL`) son *Application Items* de APEX, disponibles durante toda la sesión sin tener que volver a consultar la base en cada página.

## Los 4 Authorization Schemes

| Esquema | Condición | Para qué se usa |
|---|---|---|
| `es-administrador` | `G_ROL_USUARIO = 'ADMIN'` | Acciones destructivas (ej. borrar un registro) |
| `es-staff` | `G_ROL_USUARIO IN ('ADMIN','TECNICO')` | Todas las páginas internas del CMMS |
| `es-cliente` | `G_ROL_USUARIO IN ('CLIENTE','CLIENTE_ADMIN')` | El portal de tickets del cliente |
| `puede-usar-tickets` | `G_ROL_USUARIO IS NOT NULL` | La página de creación/edición de tickets, compartida entre staff y clientes |

## Doble capa de protección

1. **A nivel de página**: cada página tiene un Authorization Scheme asignado. Si un Cliente intenta entrar a una página interna escribiendo la URL directamente, APEX se lo bloquea — no depende de que el menú esté oculto.
2. **A nivel de menú**: además, cada entrada del menú lateral tiene su propio esquema de autorización, así un usuario ni siquiera *ve* las opciones a las que no tiene acceso.

## Cómo dar de alta al primer administrador

Como el sistema resuelve el rol buscando el usuario de APEX en las tablas, hace falta un primer registro. Esto ya está automatizado en `Base de datos/04_ALTA_ADMIN.sql`:

1. El script primero corre `SELECT SYS_CONTEXT('APEX$SESSION', 'APP_USER') FROM DUAL;` para mostrar con qué usuario estás logueado en APEX en ese momento.
2. Con ese valor, inserta (o si ya existe, actualiza a `ROL = 'ADMIN'`) el registro correspondiente en `OP_TECNICOS`.
3. Es idempotente: se puede volver a correr sin duplicar el registro.

No hace falta escribir el `INSERT` a mano — alcanza con ejecutar el script y confirmar el usuario que va a quedar como admin.
