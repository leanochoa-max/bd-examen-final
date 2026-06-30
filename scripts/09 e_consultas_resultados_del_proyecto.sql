-- 04_consultas_resultados_del_proyecto.sql
-- Crea vistas de apoyo y luego devuelve consultas útiles para el proyecto.

CREATE OR REPLACE VIEW ventas_stock.vw_detalle_ventas_calculado AS
SELECT
    v.id_venta,
    v.fecha_venta,
    cv.nombre_canal_venta,
    f.nombre_feria,
    mp.nombre_medio_pago,
    v.comision_porcentual_aplicada,
    dv.id_detalle_venta,
    pc.id_producto_comercializable,
    d.nombre_diseno,
    a.nombre_articulo,
    dv.cantidad,
    dv.precio_unitario_historico,
    dv.costo_unitario_historico,
    (dv.cantidad * dv.precio_unitario_historico) AS ingreso_bruto,
    (dv.cantidad * dv.costo_unitario_historico) AS costo_total,
    ((dv.cantidad * dv.precio_unitario_historico) * v.comision_porcentual_aplicada / 100.0) AS comision_monto,
    ((dv.cantidad * dv.precio_unitario_historico)
        - (dv.cantidad * dv.costo_unitario_historico)
        - ((dv.cantidad * dv.precio_unitario_historico) * v.comision_porcentual_aplicada / 100.0)
    ) AS ganancia_neta
FROM ventas_stock.detalle_ventas AS dv
JOIN ventas_stock.ventas AS v ON v.id_venta = dv.id_venta
JOIN ventas_stock.canales_venta AS cv ON cv.id_canal_venta = v.id_canal_venta
LEFT JOIN ventas_stock.ferias AS f ON f.id_feria = v.id_feria
JOIN ventas_stock.medios_pago AS mp ON mp.id_medio_pago = v.id_medio_pago
JOIN ventas_stock.productos_comercializables AS pc ON pc.id_producto_comercializable = dv.id_producto_comercializable
JOIN ventas_stock.disenos AS d ON d.id_diseno = pc.id_diseno
JOIN ventas_stock.articulos AS a ON a.id_articulo = pc.id_articulo;

CREATE OR REPLACE VIEW ventas_stock.vw_ventas_resumen AS
SELECT
    id_venta,
    fecha_venta,
    nombre_canal_venta,
    nombre_feria,
    nombre_medio_pago,
    comision_porcentual_aplicada,
    SUM(cantidad) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(costo_total) AS costo_total,
    SUM(comision_monto) AS comision_monto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_detalle_ventas_calculado
GROUP BY
    id_venta,
    fecha_venta,
    nombre_canal_venta,
    nombre_feria,
    nombre_medio_pago,
    comision_porcentual_aplicada;

CREATE OR REPLACE VIEW ventas_stock.vw_stock_actual AS
SELECT
    pc.id_producto_comercializable,
    d.nombre_diseno,
    a.nombre_articulo,
    COALESCE(SUM(ms.cantidad), 0) AS stock_actual
FROM ventas_stock.productos_comercializables AS pc
JOIN ventas_stock.disenos AS d ON d.id_diseno = pc.id_diseno
JOIN ventas_stock.articulos AS a ON a.id_articulo = pc.id_articulo
LEFT JOIN ventas_stock.movimientos_stock AS ms ON ms.id_producto_comercializable = pc.id_producto_comercializable
GROUP BY
    pc.id_producto_comercializable,
    d.nombre_diseno,
    a.nombre_articulo;

CREATE OR REPLACE VIEW ventas_stock.vw_stock_acumulado AS
SELECT
    ms.id_movimiento_stock,
    ms.id_producto_comercializable,
    d.nombre_diseno,
    a.nombre_articulo,
    tms.nombre_tipo_movimiento_stock,
    ms.fecha_movimiento,
    ms.cantidad,
    SUM(ms.cantidad) OVER (
        PARTITION BY ms.id_producto_comercializable
        ORDER BY ms.fecha_movimiento, ms.id_movimiento_stock
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS stock_acumulado
FROM ventas_stock.movimientos_stock AS ms
JOIN ventas_stock.productos_comercializables AS pc ON pc.id_producto_comercializable = ms.id_producto_comercializable
JOIN ventas_stock.disenos AS d ON d.id_diseno = pc.id_diseno
JOIN ventas_stock.articulos AS a ON a.id_articulo = pc.id_articulo
JOIN ventas_stock.tipos_movimiento_stock AS tms ON tms.id_tipo_movimiento_stock = ms.id_tipo_movimiento_stock;

-- 1. Ventas por día.
SELECT
    fecha_venta,
    COUNT(*) AS cantidad_ventas,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_ventas_resumen
GROUP BY fecha_venta
ORDER BY fecha_venta;

-- 2. Ventas y ganancias por canal.
SELECT
    nombre_canal_venta,
    COUNT(*) AS cantidad_ventas,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_ventas_resumen
GROUP BY nombre_canal_venta
ORDER BY ganancia_neta DESC;

-- 3. Ventas y ganancias por feria.
SELECT
    nombre_feria,
    COUNT(*) AS cantidad_ventas,
    SUM(unidades_vendidas) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_ventas_resumen
WHERE nombre_feria IS NOT NULL
GROUP BY nombre_feria
ORDER BY ganancia_neta DESC;

-- 4. Productos más vendidos.
SELECT
    nombre_diseno,
    nombre_articulo,
    SUM(cantidad) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_detalle_ventas_calculado
GROUP BY nombre_diseno, nombre_articulo
ORDER BY unidades_vendidas DESC, ganancia_neta DESC
LIMIT 15;

-- 5. Diseños más vendidos.
SELECT
    nombre_diseno,
    SUM(cantidad) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_detalle_ventas_calculado
GROUP BY nombre_diseno
ORDER BY unidades_vendidas DESC, ganancia_neta DESC;

-- 6. Artículos más vendidos.
SELECT
    nombre_articulo,
    SUM(cantidad) AS unidades_vendidas,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_detalle_ventas_calculado
GROUP BY nombre_articulo
ORDER BY unidades_vendidas DESC, ganancia_neta DESC;

-- 7. Stock actual por producto.
SELECT
    id_producto_comercializable,
    nombre_diseno,
    nombre_articulo,
    stock_actual
FROM ventas_stock.vw_stock_actual
ORDER BY stock_actual ASC, nombre_diseno, nombre_articulo;

-- 8. Ejemplo de consulta por rango de fechas.
SELECT
    fecha_venta,
    nombre_canal_venta,
    SUM(ingreso_bruto) AS ingreso_bruto,
    SUM(ganancia_neta) AS ganancia_neta
FROM ventas_stock.vw_ventas_resumen
WHERE fecha_venta BETWEEN DATE '2025-07-01' AND DATE '2025-07-31'
GROUP BY fecha_venta, nombre_canal_venta
ORDER BY fecha_venta, nombre_canal_venta;
