# Roadmap

## ✅ Hecho

### Base de datos — 17 tablas, 8 paquetes PL/SQL, 3 triggers, 6 vistas de KPI (scripts `01`–`11`)
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
- [x] Scripts consolidados y reproducibles desde cero (`00_RESET_TOTAL` → `11_DATOS_DEMO_AUDITORIA`, migraciones incrementales)

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
- [x] Órdenes de Trabajo estilo Mantis (severidad/prioridad/pasos a reproducir) — sin adjunto todavía
- [x] 4 Authorization Schemes + resolución automática de rol al iniciar sesión

## 🔴 Pendiente en el núcleo interno

- [ ] Adjuntos en Órdenes de Trabajo (`fileUpload`, todavía sin probar en este proyecto)

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
