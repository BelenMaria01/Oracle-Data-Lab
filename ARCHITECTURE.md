# Arquitectura del Sistema

## Visión general

La aplicación tiene dos grandes bloques funcionales que comparten la misma base de datos y, en varios casos, las mismas páginas:

```
┌─────────────────────────────────────────────────────────────┐
│                      APLICACIÓN APEX                         │
│                                                                │
│  ┌──────────────────────┐        ┌──────────────────────┐   │
│  │   NÚCLEO CMMS         │        │   PORTAL DE TICKETS   │   │
│  │   (uso interno)       │        │   (staff + clientes)  │   │
│  │                       │◄──────►│                        │   │
│  │  - Inventario IT      │        │  - Órdenes de Trabajo │   │
│  │  - Técnicos           │        │    = Tickets          │   │
│  │  - Repuestos          │        │  - Mis Tickets         │   │
│  │  - Proveedores        │        │  - Chat por ticket     │   │
│  │  - Ubicaciones        │        │                        │   │
│  │  - Dashboard          │        │                        │   │
│  └──────────────────────┘        └──────────────────────┘   │
│                                                                │
│              Todo protegido por 3 roles: Admin / Técnico / Cliente
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                  Oracle Autonomous Database
                  (17 tablas, 8 paquetes PL/SQL, 3 triggers)
```

> Estado de build: el **Núcleo CMMS** y la vista de **Órdenes de Trabajo** (lado staff) están 100% terminados. **Mis Tickets** y el **Chat por ticket** (lado cliente) todavía no tienen UI — el modelo de datos ya existe (`OP_ORDEN_MENSAJES`, `ID_CLIENTE` en `OP_ORDENES_TRABAJO`).

## Decisión de diseño central: "Orden de Trabajo" = "Ticket"

Al principio del proyecto se evaluó crear una tabla `TICKETS` separada para las incidencias reportadas por clientes. Se descartó esa idea: un ticket de cliente **es** una Orden de Trabajo — mismo registro, misma tabla (`OP_ORDENES_TRABAJO`), solo que:

- Cuando lo crea un cliente, queda vinculado a su `ID_CLIENTE`
- Cuando lo crea el staff, puede no tener cliente asociado (mantenimiento interno/preventivo)
- El formulario de creación es **la misma página** para ambos casos

Esto evita duplicar lógica, evita tener que sincronizar dos tablas, y refleja mejor la realidad: da igual quién reporta el problema, el flujo de resolución es el mismo.

## El formulario de ticket está inspirado en Mantis Bug Tracker

Se tomó como referencia de diseño el formulario de reporte de incidencias de [Mantis Bug Tracker](https://mantisbt.org), adaptando solo lo que tiene sentido para mantenimiento de hardware (no todo lo de un bug tracker de software aplica):

| Campo tomado de Mantis | Adaptación en este proyecto |
|---|---|
| Categoría / Proyecto | Activo afectado (qué equipo tiene el problema) |
| Severidad | Igual (Trivial / Menor / Mayor / Crítica) |
| Prioridad | Igual (Baja / Media / Alta / Crítica) |
| Resumen | Título |
| Descripción | Igual |
| Pasos para reproducir | Igual |
| Adjuntos | Igual (captura de pantalla, documento) |
| ~~Versión del producto~~ | **Descartado** — es un concepto de software, no aplica a hardware físico |

## Patrón de interfaz: "wizard" oscuro reutilizable

Todos los formularios de creación/edición de la aplicación siguen el mismo patrón visual, construido una vez y replicado:

- Modal oscuro, con barra lateral de pasos (para formularios largos) o de un solo paso (formularios cortos)
- Campos agrupados en una grilla de 2 columnas, con icono por campo
- Botones propios (Cancelar / Siguiente / Guardar), en vez de los botones nativos de APEX — se optó por esto porque los botones nativos no se renderizaban correctamente dentro de un modal complejo
- El guardado real se dispara con `apex.page.submit()`, la función oficial de APEX, no simulando clics en botones ocultos

## Seguridad: resuelta a nivel de sesión, no de página por página

Al iniciar sesión, un proceso de aplicación (`appProcess`) resuelve automáticamente el rol del usuario logueado:

1. Busca el usuario en `OP_TECNICOS` (si es Admin o Técnico)
2. Si no lo encuentra ahí, busca en `OP_CLIENTES` (si es Cliente o Cliente Admin)
3. Guarda el resultado en variables de aplicación (`G_ROL_USUARIO`, `G_ID_TECNICO_ACTUAL`, `G_ID_CLIENTE_ACTUAL`)

A partir de ahí, cada página y cada entrada de menú se protege consultando esas variables — ver detalle completo en [`ROLES_Y_SEGURIDAD.md`](./ROLES_Y_SEGURIDAD.md).
