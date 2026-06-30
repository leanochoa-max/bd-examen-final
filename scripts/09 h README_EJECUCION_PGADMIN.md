# Instrucciones rápidas para ejecutar en pgAdmin 4

Este paquete implementa la base `bd_examen` con el esquema `ventas_stock`.

## Orden de ejecución

1. `00_crear_base_bd_examen.sql`
2. `01_crear_esquema_y_tablas.sql`
3. `02_cargar_datos_desde_excel_corregido.sql`
4. `04_consultas_resultados_del_proyecto.sql`

## Qué hace cada archivo

- `00`: crea desde cero la base de datos `bd_examen`.
- `01`: crea el esquema `ventas_stock` y las tablas.
- `02`: carga los datos del Excel corregido mediante `INSERT`.
- `03`: crea vistas y devuelve consultas de resultados.


## Advertencia (LO)

Los scripts `00` y `01` reconstruyen objetos desde cero. Si los vuelvo a ejecutar se borrará lo creado previamente.
