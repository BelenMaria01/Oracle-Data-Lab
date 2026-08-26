# Roadmap

## 🗺️ Mapa completo de la aplicación

### 1️⃣ Núcleo interno (Staff / Admin)
- Home — dashboard con KPIs, gráficos, alertas
- Inventario IT — todo el hardware (equipos, con Tipo/Ubicación/Proveedor/Técnico asociados)
- Catálogos — Tipos de Activo, Ubicaciones, Proveedores
- Técnicos — con flujo de Alta/Baja
- Repuestos + Movimientos de Stock (entradas/salidas de almacén)
- Auditoría — registro de cambios
- Notificaciones — stock bajo, asignaciones
- Informe de Costes — analítica

### 2️⃣ Órdenes de Trabajo = Tickets (el corazón de la app)
- Un mismo concepto, dos caras: internamente es "mantenimiento", para el cliente es "reportar una incidencia"
- Estilo Mantis: severidad, prioridad, pasos para reproducir, adjuntos, estados (Nuevo → En Proceso → Resuelto → Cerrado)

### 3️⃣ Portal de Clientes (externo)
- Mis Tickets — solo los suyos
- Nuevo Ticket — comparte la misma página que usa el staff
- Chat del ticket — conversación con el técnico
- (a futuro) gestión de usuarios de su propia empresa

### 4️⃣ Para empleados/técnicos
- Mis Órdenes Asignadas — solo lo que le toca a cada uno
- Panel/perfil del técnico — sus estadísticas
- Calendario de mantenimientos programados
- Chat en tickets asignados
- Base de conocimiento interna

### 5️⃣ Roles y seguridad (transversal a todo)
- **Admin**: ve y gestiona todo
- **Técnico**: ve todo lo operativo, no lo exclusivo de Admin
- **Cliente**: solo su portal

---

## ✅ Hecho

### Base de datos — 17 tablas, 8 paquetes PL/SQL, 3 triggers, 6 vistas de KPI (scripts `00`–`12`)
- [x] Sistema de roles a nivel de datos (Admin/Técnico en `OP_TECNICOS`, Cliente/Cliente Admin en `OP_CLIENTES`)
- [x] Modelo de Órdenes de Trabajo ampliado a estilo Mantis (severidad, pasos para reproducir, adjuntos, 6 estados)
- [x] Modelo de empresas cliente (varios usuarios por empresa)
- [x] Calendario de mantenimientos programados (`OP_MANTENIMIENTOS_PROGRAMADOS` + `PKG_MANTENIMIENTOS`) — genera órdenes automáticamente al vencer
- [x] Base de conocimiento interna (`OP_ARTICULOS_KB` + `PKG_KB`)
- [x] Vistas de KPI listas para bindear en Home/paneles (`VW_KPI_ORDENES_ESTADO`, `VW_KPI_ACTIVOS_ESTADO`, `VW_KPI_ORDENES_TECNICO`, `VW_MANTENIMIENTOS_PROXIMOS`, `VW_KPI_TECNICOS_ACTIVO`, `VW_KPI_REPUESTOS_BAJO_MINIMO`)
- [x] Trigger que sella `FECHA_BAJA` automáticamente al dar de baja un técnico (`05_TECNICOS_BAJA.sql`)
- [x] Alta de admin automatizada por script, sin INSERT manual (`04_ALTA_ADMIN.sql`)
- [x] Fix del `ORA-01422` al iniciar sesión: dedup + UNIQUE constraint en `OP_TECNICOS.USUARIO_APEX` (`08_FIX_LOGIN_DUPLICADOS.sql`)
- [x] Datos de demo (catálogos, técnicos, equipos, repuestos, movimientos, auditoría — `07`, `09`, `10`, `11`)
- [x] 8 Órdenes de Trabajo de ejemplo cubriendo los 6 estados, creadas vía `PKG_ORDENES` (`12_DATOS_DEMO_ORDENES.sql`)
- [x] Scripts consolidados y reproducibles desde cero (`00_RESET_TOTAL` → `12_DATOS_DEMO_ORDENES`, migraciones incrementales)

### Aplicación APEX — núcleo interno 100% completo (21 páginas, todas importadas y funcionando)
- [x] Página 0 (Global Page) y Página 9999 (Login)
- [x] Página 1 (Home) — dashboard con KPIs, gráfico dona, gráfico barras/línea y tablas "requiere atención"
- [x] Catálogos: Tipos de Activo, Ubicaciones, Proveedores (páginas 2-7)
- [x] Técnicos, con flujo de Alta/Baja (toggle + trigger DB)
- [x] Inventario IT / Activos — con KPIs, gráficos, avatares, buscador
- [x] Repuestos + Movimientos de Stock (el registro pasa por `PKG_INVENTARIO`, no hace INSERT directo)
- [x] Auditoría (solo lectura, `@es-administrador`)
- [x] Notificaciones (marcar leída / marcar todas leídas)
- [x] Informe de Costes — KPIs + gráficos + tabla de proveedores
- [x] 4 Authorization Schemes + resolución automática de rol al iniciar sesión

### Órdenes de Trabajo — rediseño estilo Mantis Bug Tracker (V0.8.0)
- [x] Modal "Nueva/Editar Orden" reestructurado en grilla tipo Mantis: filas Equipo/Tipo, Prioridad/Severidad, Estado/Técnico, con Título/Descripción/Pasos a ancho completo
- [x] Tema oscuro del proyecto, modal ampliado (1100px)
- [x] Campo de adjunto (`fileUpload`, storage `appTempFiles`) restringido a PDF/XLSX/XLS
- [x] Proceso PL/SQL que copia el archivo a `ADJUNTO_CONTENIDO`/`ADJUNTO_MIME`/`ADJUNTO_NOMBRE` tras el submit

### Portal de Clientes — primera versión (V0.9.0)
- [x] Página 21 "Mis Tickets" — listado filtrado por `G_ID_CLIENTE_ACTUAL`, mismo estilo de badges/buscador que Órdenes de Trabajo, protegida por `@es-cliente`
- [x] "Nuevo Ticket" reutiliza la página 20 (mismo formulario que usa el staff), ahora accesible a `@puede-usar-tickets` (staff + cliente)
- [x] Campos de uso interno (Estado, Técnico Asignado) ocultos en el formulario cuando el rol es Cliente/Cliente Admin
- [x] Proceso que fuerza `ID_CLIENTE` = cliente logueado y protege Estado/Técnico Asignado contra manipulación cuando quien guarda es un cliente
- [x] Guardia de propiedad: si un cliente intenta abrir una orden que no es suya (por URL directa), se lo redirige a Mis Tickets
- [x] Chat del ticket — región "Mensajes" sobre `OP_ORDEN_MENSAJES`, visible solo con orden ya creada, con envío por AJAX (sin recargar el formulario) para cliente y staff
- [x] Entrada de menú "Mis Tickets" (solo clientes, vía el mismo esquema de autorización que ya ocultaba el resto del menú)

### Para empleados/técnicos — primera versión (V1.0.0)
- [x] Página 22 "Mis Órdenes Asignadas" — listado filtrado por `G_ID_TECNICO_ACTUAL`, ordenado por estado (abiertas primero)
- [x] Página 23 "Mi Panel" — KPIs (órdenes abiertas, resueltas este mes, total histórico, críticas abiertas vía `VW_KPI_ORDENES_TECNICO`), perfil básico y últimas 10 órdenes
- [x] Página 24 "Calendario de Mantenimientos" — listado sobre `VW_MANTENIMIENTOS_PROXIMOS`, con botón a Nueva Programación
- [x] Página 25 "Programación de Mantenimiento" — formulario CRUD directo sobre `OP_MANTENIMIENTOS_PROGRAMADOS` (sin el wizard oscuro elaborado, formulario simple)
- [x] Página 26 "Base de Conocimiento" — listado de `OP_ARTICULOS_KB` con buscador
- [x] Página 27 "Artículo KB" — formulario de creación/edición, autor automático (`G_ID_TECNICO_ACTUAL`), registra vista vía `PKG_KB.registrar_vista` al abrir un artículo existente
- [x] Chat en tickets asignados — ya cubierto por la misma región de Mensajes de la página 20 (es la misma UI para cliente y técnico)
- [x] 5 entradas de menú nuevas (Mis Tickets ya contaba, más Mis Órdenes Asignadas, Mi Panel, Calendario de Mantenimientos, Base de Conocimiento)

## 🔴 Pendiente en el núcleo interno / Órdenes de Trabajo

- [ ] **Probar el adjunto de punta a punta** — subir un archivo real y confirmar que se guarda correctamente en la orden (implementado pero sin probar en producción todavía)
- [ ] Mostrar/descargar el adjunto ya subido — falta un link de descarga en el listado o el detalle de la orden

## ✅ Visibilidad de Órdenes de Trabajo restringida por rol (V1.8.0)

Antes, "Órdenes de Trabajo" (página 19) mostraba TODAS las órdenes (asignadas o no) a cualquier miembro del staff, técnico o admin, estilo mesa de trabajo compartida. Se cambió a pedido: ahora el Técnico solo ve en esa página (listado y KPIs) las órdenes que tiene asignadas a sí mismo (`o.id_tecnico_asignado = :G_ID_TECNICO_ACTUAL`); el Admin sigue viendo todo. El botón "Nueva Orden" no se tocó, así que el técnico puede seguir creando tickets nuevos.

- [ ] Nota: un técnico que crea un ticket y no se lo autoasigna, no lo va a ver en su propio listado hasta que alguien se lo asigne (ni a él ni a nadie). No se cambió porque no fue parte del pedido — avisar si se quiere que el creador también vea sus propios tickets sin asignar.

## ✅ Página 28 (Detalle de Orden) — confirmada funcionando de punta a punta (V1.5.0)

Click en el ID desde Órdenes de Trabajo / Mis Tickets / Mis Órdenes Asignadas → abre el detalle correctamente, con Título/Descripción/Pasos/Historial de Estados poblados, chat funcionando, y botón Volver (declarativo, sin JS) llevando de nuevo al listado según el rol. Quedó pendiente solo:

- [ ] Repuestos Utilizados sigue vacío en las 8 órdenes demo (nunca se cargó ningún repuesto de ejemplo) — no es bug, falta dato y falta UI para cargar repuestos a una orden real
- [ ] Adjunto: el nombre se muestra pero no hay link de descarga todavía (ver arriba)

## ✅ Fix estructural: navegación con checksum (V1.2.0 / V1.3.0)

Se encontró y corrigió un bug presente **desde el origen de la app**, no introducido en esta sesión: el patrón de "click en el ID de una fila para editar" usaba `apex.util.makeApplicationUrl` del lado del cliente, que no calcula un checksum válido al navegar hacia otra página cuando `pageAccessProtection: argumentsMustHaveChecksum` está activo (está activo en todas las páginas). Esto rompía el click-para-editar en **13 páginas**, incluidas 7 que existían antes de esta sesión y nunca se habían probado con ese flujo:

- p02 Tipos de Activo, p04 Ubicaciones, p06 Proveedores, p08 Técnicos (se convirtieron de `tableName` a `sqlQuery` explícito)
- p10 Inventario IT, p12 Repuestos, p17 Notificaciones
- p19 Órdenes de Trabajo, p21 Mis Tickets, p22 Mis Órdenes Asignadas, p24 Calendario, p26 Base de Conocimiento, p28 Detalle de Orden (botón Editar)

Solución aplicada en todas: generar la URL completa (con checksum) **del lado del servidor** vía `APEX_PAGE.GET_URL`, como una columna oculta más del listado, en vez de reconstruirla en JS.

## 🔴 Pendiente en el Portal de Clientes (V0.9.0, recién construido, sin probar)

- [ ] **Probar todo el flujo de punta a punta**: login como cliente, ver "Mis Tickets", crear un ticket nuevo, confirmar que no puede tocar Estado/Técnico, mandar un mensaje en el chat, y confirmar que no puede abrir el ticket de otro cliente por URL
- [x] "Todos los tickets" de la empresa del cliente (no solo los propios) — página 29 "Tickets Empresa", agregada en V1.8.0. `cliente_demo` se subió a rol `CLIENTE_ADMIN` (`16_CLIENTE_DEMO_ADMIN.sql`) para poder probarla. Se agregaron 4 órdenes demo atadas a `cliente_demo` cubriendo NUEVO/EN_PROCESO/RESUELTO/CERRADO (`17_DATOS_DEMO_TICKETS_CLIENTE_DEMO.sql`), ya que las 8 órdenes de `12_DATOS_DEMO_ORDENES.sql` no tienen `ID_CLIENTE` y por eso el portal aparecía siempre vacío. Pendiente: prueba de punta a punta.
- [ ] (a futuro) gestión de usuarios: que un Cliente Admin invite a otros de su empresa
- [ ] El chat hoy es un formulario simple (reporte + textarea + botón); si querés algo más "burbujas de chat" hay que agregar estilo visual encima

## ✅ Página 30 (Mi Perfil) — nueva, pendiente de probar de punta a punta

Datos de contacto editables (Nombre/Email/Teléfono sobre `OP_CLIENTES`), bloque de solo lectura con Empresa/Rol/Cliente Desde, y cambio de contraseña propio vía `APEX_UTIL.RESET_PASSWORD` (requiere la contraseña actual, `p_change_password_on_first_use => FALSE` para no forzar otro cambio en el próximo login). Visible para Cliente y Cliente Admin. Agregada al menú "Portal de Cliente" y al breadcrumb.

- [ ] Probar de punta a punta: guardar datos de contacto, y cambiar la contraseña de `cliente_demo` (confirmar que el nuevo login funciona)
- [ ] Se detectó de paso que la página 29 "Tickets Empresa" nunca tuvo entrada en `shared-components/breadcrumbs.apx` (falta desde que se creó en V1.8.0) — no se tocó porque no era parte de este pedido

## 🔴 Pendiente en el bloque de empleados/técnicos (V1.0.0, recién construido, sin probar)

- [ ] **Probar todo el flujo de punta a punta**: Mis Órdenes Asignadas, Mi Panel, crear una Programación de Mantenimiento, crear un Artículo KB y confirmar que se guarda el autor y suma la vista al reabrirlo
- [ ] Las páginas 25 (Programación) y 27 (Artículo KB) usan formularios simples, sin el wizard oscuro con sidebar que tienen el resto de las páginas de creación — se puede vestir igual más adelante si se quiere consistencia visual total
- [ ] `P27_CONTENIDO` usa `dataType: clob` — es la primera vez que se usa ese tipo en este proyecto, sin confirmar contra un import real
- [ ] Nadie corre todavía `PKG_MANTENIMIENTOS.generar_ordenes_vencidas` — hace falta un job programado (`DBMS_SCHEDULER`) o un botón manual para que las programaciones vencidas generen órdenes automáticamente

## 🔮 Visión a futuro: Big Data + IA

Dirección a explorar más adelante, todavía sin desarrollar:

- Mantenimiento predictivo (anticipar fallos de equipos según su historial)
- Análisis automático de tickets (clasificación de severidad/prioridad sugerida por IA a partir de la descripción)
- Dashboards analíticos más avanzados sobre el histórico acumulado
- Posible chatbot de soporte de primer nivel para el portal de clientes

*(Esta sección se irá completando a medida que la idea tome forma más concreta.)*
