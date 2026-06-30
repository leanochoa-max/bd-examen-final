-- 00_crear_base_bd_examen.sql
-- Crea desde cero la base de datos bd_examen.
-- Debe ejecutarse conectado a una base distinta de bd_examen, por ejemplo postgres.

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'bd_examen'
  AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS bd_examen;

CREATE DATABASE bd_examen
    WITH ENCODING = 'UTF8'
    TEMPLATE = template0;
