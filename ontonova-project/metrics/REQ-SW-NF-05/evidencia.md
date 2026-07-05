# REQ-SW-NF-05 — Despliegue por terceros con la documentación

**Métrica:** un tercero puede desplegar el sistema siguiendo únicamente la documentación del repositorio.
**Método (ISO/IEC/IEEE 29148):** Demostración.

## Demostración
La documentación de despliegue vive en el `README.md` raíz del repositorio (con
los README de backend y frontend enlazados a él). El procedimiento documentado
se reduce a dos pasos que no exigen conocimiento del código:

1. Requisitos previos: Docker con Compose y una GPU con NVIDIA Container Toolkit.
2. `docker compose up -d` en la raíz del proyecto.

La demostración ejecutable es la misma medición de REQ-SW-NF-08: partiendo de
cero (contenedores y red eliminados), el comando documentado levanta la pila
completa y operativa en 126 s sin ninguna intervención adicional. Toda la
configuración variable (modelo, límites, URLs) tiene valores por defecto
funcionales y se sobreescribe vía `.env` documentado (ver REQ-SW-FC-02),
de modo que el camino del tercero no requiere editar ficheros.

Refuerzo: la prueba e2e de aceptación scrum-4 se ejecuta contra un despliegue
levantado exactamente con ese procedimiento, de modo que cada ejecución de la
suite re-demuestra el requisito.
