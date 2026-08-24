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

🔶 **En construcción activa.** El diseño de base de datos está terminado y probado. La aplicación se está reconstruyendo pieza por pieza sobre una base limpia.

Ver `[ROADMAP.md](./ROADMAP.md)` para el detalle de qué está hecho y qué falta.

## Documentación

| Archivo                                          | Contenido                                             |
| ------------------------------------------------ | ----------------------------------------------------- |
| `[ARCHITECTURE.md](./ARCHITECTURE.md)`           | Cómo está construido por dentro, decisiones de diseño |
| `[DATABASE.md](./DATABASE.md)`                   | Modelo de datos completo                              |
| `[ROLES_Y_SEGURIDAD.md](./ROLES_Y_SEGURIDAD.md)` | Los 3 roles de usuario y cómo se protege cada parte   |
| `[ROADMAP.md](./ROADMAP.md)`                     | Estado actual y visión a futuro                       |



## Instalación

Requiere una instancia de **Oracle Autonomous Database** con **Oracle APEX** habilitado.

1. Ejecutar los scripts de `/db` en orden (`01_TABLAS.sql` → `02_PAQUETES.sql` → `03_TRIGGERS.sql`)
2. Dar de alta al primer usuario administrador en `OP_TECNICOS` (ver detalle en `ROLES_Y_SEGURIDAD.md`)
3. Importar la aplicación APEX desde App Builder → Import
