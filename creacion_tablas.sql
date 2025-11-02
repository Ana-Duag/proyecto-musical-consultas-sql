
/* CREACIÓN DE CLAVE PRIMARIA Y CLAVE FORÁNEA */

USE prueba_music_stream_proyecto

-- Definir clave primaria en artistas
ALTER TABLE artistas
MODIFY COLUMN Artist VARCHAR(100) NOT NULL,
ADD PRIMARY KEY (Artist);


-- Ajustar columna name_artist en canciones
ALTER TABLE canciones
MODIFY COLUMN name_artist VARCHAR(100);


-- Limpiar artistas huérfanos
SET SQL_SAFE_UPDATES = 0;   -- desactivamos modo seguro
UPDATE canciones c
LEFT JOIN artistas a ON c.name_artist = a.Artist
SET c.name_artist = NULL
WHERE a.Artist IS NULL;
SET SQL_SAFE_UPDATES = 1; -- activamos modo seguro


-- Crear índice sobre name_artist
CREATE INDEX idx_name_artist ON canciones(name_artist);


-- Crear la clave foránea
ALTER TABLE canciones
ADD CONSTRAINT fk_canciones_artistas
FOREIGN KEY (name_artist)
REFERENCES artistas(Artist)
ON UPDATE CASCADE
ON DELETE SET NULL;




