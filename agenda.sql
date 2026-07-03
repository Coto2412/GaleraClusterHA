-- Eliminar y crear base de datos limpia
DROP DATABASE IF EXISTS agenda;
CREATE DATABASE agenda;
USE agenda;

-- =========================
-- TABLAS
-- =========================

-- Tabla de usuarios
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    ciudad VARCHAR(100)
);

-- Tabla de contactos
CREATE TABLE contactos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    nombre VARCHAR(100),
    relacion VARCHAR(50),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Tabla de teléfonos
CREATE TABLE telefonos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contacto_id INT,
    numero VARCHAR(20),
    tipo VARCHAR(20),
    FOREIGN KEY (contacto_id) REFERENCES contactos(id)
);

-- =========================
-- DATOS
-- =========================

-- Insertar usuarios
INSERT INTO usuarios (nombre, email, ciudad) VALUES
('Ana Pérez', 'ana@example.com', 'Santiago'),
('Luis Gómez', 'luis@example.com', 'Valparaíso'),
('Carla Rojas', 'carla@example.com', 'Concepción');

-- Insertar contactos (usando SELECT para evitar problemas con IDs)
INSERT INTO contactos (usuario_id, nombre, relacion)
SELECT id, 'María Pérez', 'Hermana' FROM usuarios WHERE nombre='Ana Pérez';

INSERT INTO contactos (usuario_id, nombre, relacion)
SELECT id, 'Juan Soto', 'Amigo' FROM usuarios WHERE nombre='Ana Pérez';

INSERT INTO contactos (usuario_id, nombre, relacion)
SELECT id, 'Pedro Gómez', 'Padre' FROM usuarios WHERE nombre='Luis Gómez';

INSERT INTO contactos (usuario_id, nombre, relacion)
SELECT id, 'Laura Rojas', 'Madre' FROM usuarios WHERE nombre='Carla Rojas';

-- Insertar teléfonos (también dinámico)
INSERT INTO telefonos (contacto_id, numero, tipo)
SELECT id, '912345678', 'Móvil' FROM contactos WHERE nombre='María Pérez';

INSERT INTO telefonos (contacto_id, numero, tipo)
SELECT id, '221234567', 'Fijo' FROM contactos WHERE nombre='María Pérez';

INSERT INTO telefonos (contacto_id, numero, tipo)
SELECT id, '934567890', 'Móvil' FROM contactos WHERE nombre='Juan Soto';

INSERT INTO telefonos (contacto_id, numero, tipo)
SELECT id, '945678901', 'Móvil' FROM contactos WHERE nombre='Pedro Gómez';

INSERT INTO telefonos (contacto_id, numero, tipo)
SELECT id, '956789012', 'Móvil' FROM contactos WHERE nombre='Laura Rojas';