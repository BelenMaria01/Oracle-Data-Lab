# CMMS + Portal de Soporte Externo

Sistema de gestión de mantenimiento de activos IT (**CMMS** — *Computerized Maintenance Management System*), con un portal externo de tickets estilo **Mantis Bug Tracker** integrado en la misma aplicación.

## ¿Qué es esto?

Una única aplicación con dos caras:

- **Hacia adentro**: gestión completa del inventario IT de la empresa (equipos, técnicos, repuestos, proveedores, ubicaciones) y el mantenimiento que se les hace.
- **Hacia afuera**: un portal donde clientes externos (u otras áreas de la empresa) pueden entrar, reportar una incidencia como un "ticket", hacer seguimiento y chatear con el técnico asignado.

La idea clave: **un ticket de cliente y una orden de trabajo interna son el mismo registro**. No hay dos sistemas separados — es el mismo concepto de mantenimiento visto desde dos ángulos distintos, según quién lo mira.

## Stack tecnológico

- **Oracle APEX** (low-code, sobre Oracle Autonomous Database)
- **PL/SQL** para toda la lógica de negocio (paquetes, triggers)
- **APEXlang** como formato de exportación/versión de la aplicación (permite versionar la app como archivos de texto, ideal para Git)

## Estado actual

🟢 **Núcleo interno 100% completo.** Las 21 páginas de la aplicación están importadas y funcionando (dashboard, catálogos, inventario, técnicos, repuestos, movimientos de stock, auditoría, notificaciones, informe de costes y órdenes de trabajo estilo Mantis).

Pendiente: adjuntos en Órdenes, Portal de Clientes, y funciones de empleados (Mis Órdenes, calendario, chat, base de conocimiento). Ver `[ROADMAP.md](./ROADMAP.md)` para el detalle.

## Documentación

| Archivo                                          | Contenido                                             |
| ------------------------------------------------ | ----------------------------------------------------- |
| `[ARCHITECTURE.md](./ARCHITECTURE.md)`           | Cómo está construido por dentro, decisiones de diseño |
| `[DATABASE.md](./DATABASE.md)`                   | Modelo de datos completo                              |
| `[ROLES_Y_SEGURIDAD.md](./ROLES_Y_SEGURIDAD.md)` | Los 3 roles de usuario y cómo se protege cada parte   |
| `[ROADMAP.md](./ROADMAP.md)`                     | Estado actual y visión a futuro                       |



## Instalación

Requiere una instancia de **Oracle Autonomous Database** con **Oracle APEX** habilitado.

1. Ejecutar los scripts de `Base de datos/` **en orden numérico** (`00` solo si querés resetear desde cero, `01` a `11`)
2. `04_ALTA_ADMIN.sql` da de alta (o promueve a ADMIN) al usuario logueado actualmente en APEX — no hace falta el INSERT manual
3. Importar la aplicación APEX desde App Builder → Import (último export en `APEX/`)
