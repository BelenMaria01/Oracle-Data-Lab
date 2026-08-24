# Roadmap

## ✅ Hecho

### Base de datos — modelo de datos 100% completo para las 5 secciones del mapa
- [x] 17 tablas, 8 paquetes PL/SQL, 2 triggers (`01`–`04`)
- [x] Sistema de roles a nivel de datos (Admin/Técnico en `OP_TECNICOS`, Cliente/Cliente Admin en `OP_CLIENTES`)
- [x] Modelo de Órdenes de Trabajo ampliado a estilo Mantis (severidad, pasos para reproducir, adjuntos, 6 estados)
- [x] Modelo de empresas cliente (varios usuarios por empresa)
- [x] Calendario de mantenimientos programados (`OP_MANTENIMIENTOS_PROGRAMADOS` + `PKG_MANTENIMIENTOS`) — genera órdenes automáticamente al vencer
- [x] Base de conocimiento interna (`OP_ARTICULOS_KB` + `PKG_KB`)
- [x] Vistas de KPI listas para bindear en Home/paneles (`VW_KPI_ORDENES_ESTADO`, `VW_KPI_ACTIVOS_ESTADO`, `VW_KPI_ORDENES_TECNICO`, `VW_MANTENIMIENTOS_PROXIMOS`)
- [x] Scripts consolidados y reproducibles desde cero (`01_TABLAS` → `04_CALENDARIO_KB`, migraciones incrementales)

### Aplicación APEX — estado real en el servidor
- [x] Página 0 (Global Page)
- [x] Página 1 (Home) — shell con tema oscuro aplicado, sin KPIs todavía (placeholder)
- [x] Página 9999 (Login)
- [x] 4 Authorization Schemes + resolución automática de rol al iniciar sesión

## 🔴 Pendiente de importar con éxito (ya construido, bloqueado por errores de import)

- [ ] Catálogos: Tipos de Activo, Ubicaciones, Proveedores (páginas 2-7) — construidas y corregidas varias veces, todavía sin confirmar un import limpio
- [ ] Técnicos (con flujo de Alta/Baja)
- [ ] Inventario IT / Activos
- [ ] Repuestos + Movimientos de Stock
- [ ] Auditoría, Notificaciones, Informe de Costes (UI)
- [ ] Dashboard real de Home (conectar con las vistas VW_KPI_* ya creadas)
- [ ] Órdenes de Trabajo / Tickets estilo Mantis (UI)

## 🔜 Próximo (Portal de Clientes)

- [ ] Página "Mis Tickets" para clientes (listado filtrado por cliente)
- [ ] "Todos los tickets" de la empresa del cliente (no solo los propios)
- [ ] Ocultar campos de uso interno (técnico asignado, costes) cuando el ticket lo crea un cliente

## 🔜 Próximo (para empleados/técnicos)

- [ ] "Mis Órdenes Asignadas" — vista filtrada por técnico (dato ya disponible en `VW_KPI_ORDENES_TECNICO`)
- [ ] Panel/perfil personal del técnico (estadísticas, historial)
- [ ] Interfaz de chat sobre `OP_ORDEN_MENSAJES` (ya existe la tabla, falta la UI)
- [ ] Calendario de mantenimientos (UI sobre `VW_MANTENIMIENTOS_PROXIMOS`, modelo de datos ya listo)
- [ ] Base de conocimiento interna (UI sobre `OP_ARTICULOS_KB` + `PKG_KB`, modelo de datos ya listo)
- [ ] Página de gestión de usuarios para que un Cliente Admin invite a otros de su empresa

## 🔮 Visión a futuro: Big Data + IA

Dirección a explorar más adelante, todavía sin desarrollar:

- Mantenimiento predictivo (anticipar fallos de equipos según su historial)
- Análisis automático de tickets (clasificación de severidad/prioridad sugerida por IA a partir de la descripción)
- Dashboards analíticos más avanzados sobre el histórico acumulado
- Posible chatbot de soporte de primer nivel para el portal de clientes

*(Esta sección se irá completando a medida que la idea tome forma más concreta.)*
