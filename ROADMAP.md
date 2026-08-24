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

## 🔴 Pendiente en el núcleo interno / Órdenes de Trabajo

- [ ] **Probar el adjunto de punta a punta** — subir un archivo real y confirmar que se guarda correctamente en la orden (implementado pero sin probar en producción todavía)
- [ ] Mostrar/descargar el adjunto ya subido — falta un link de descarga en el listado o el detalle de la orden

## 🔴 Pendiente en el Portal de Clientes (V0.9.0, recién construido, sin probar)

- [ ] **Probar todo el flujo de punta a punta**: login como cliente, ver "Mis Tickets", crear un ticket nuevo, confirmar que no puede tocar Estado/Técnico, mandar un mensaje en el chat, y confirmar que no puede abrir el ticket de otro cliente por URL
- [ ] "Todos los tickets" de la empresa del cliente (no solo los propios) — para el rol Cliente Admin, todavía no implementado
- [ ] (a futuro) gestión de usuarios: que un Cliente Admin invite a otros de su empresa
- [ ] El chat hoy es un formulario simple (reporte + textarea + botón); si querés algo más "burbujas de chat" hay que agregar estilo visual encima

## 🔜 Próximo — Para empleados/técnicos

- [ ] "Mis Órdenes Asignadas" — vista filtrada por técnico (dato ya disponible en `VW_KPI_ORDENES_TECNICO`)
- [ ] Panel/perfil personal del técnico (estadísticas, historial)
- [ ] Chat en tickets asignados (misma UI que el chat del portal de clientes, vista desde el lado técnico)
- [ ] Calendario de mantenimientos (UI sobre `VW_MANTENIMIENTOS_PROXIMOS`, modelo de datos ya listo)
- [ ] Base de conocimiento interna (UI sobre `OP_ARTICULOS_KB` + `PKG_KB`, modelo de datos ya listo)

## 🔮 Visión a futuro: Big Data + IA

Dirección a explorar más adelante, todavía sin desarrollar:

- Mantenimiento predictivo (anticipar fallos de equipos según su historial)
- Análisis automático de tickets (clasificación de severidad/prioridad sugerida por IA a partir de la descripción)
- Dashboards analíticos más avanzados sobre el histórico acumulado
- Posible chatbot de soporte de primer nivel para el portal de clientes

*(Esta sección se irá completando a medida que la idea tome forma más concreta.)*
