
/* 
Se han resuelto las consultas utilizando INNER JOIN, ya que partimos de dos tablas: artistas y canciones, 
y queremos trabajar únicamente con los registros coincidentes entre ambas.

Para analizar canciones más escuchadas o artistas más populares, se ha utilizado el número de oyentes
en lugar del número de reproducciones, ya que las reproducciones pueden estar infladas por diversos factores.

No se han utilizado acentos en los alias para evitar posibles errores de reconocimiento que a veces se han producido en las consultas
*/

USE music_stream_proyecto    -- Nuestra BBDD

SELECT *
FROM artistas;

SELECT *
FROM canciones;


/* CONSULTA 1. PROMEDIO DE OYENTES DE CADA GÉNERO, ponderando por el número de canciones del artista.
Al ponderar por número de canciones del artista, se evita que artistas con pocas canciones influyan desproporcionadamente en el promedio.

Se identifica el género principal de cada artista (el género con más canciones) y se calcula un promedio ponderado multiplicando los oyentes por el número de canciones.
Esto proporciona un promedio más realista y representativo del interés por cada género. */

WITH genero_principal AS (              -- tabla temporal
    SELECT 
        name_artist,
        genre,
        COUNT(*) AS total_canciones,   -- número de canciones del artista en ese género
        ROW_NUMBER() OVER (
            PARTITION BY name_artist       -- reinicia la numeración por artista
            ORDER BY COUNT(*) DESC         -- el género con más canciones recibe rn = 1
        ) AS rn
    FROM canciones
    GROUP BY name_artist, genre
)

SELECT 
    g.genre AS genero,  
    ROUND(
        SUM(a.Listeners * g.total_canciones)  -- multiplicamos oyentes por número de canciones del artista
        / SUM(g.total_canciones)              -- dividimos por total de canciones del género para ponderar
    ) AS promedio_ponderado_oyentes
FROM genero_principal g
INNER JOIN artistas a
    ON g.name_artist = a.Artist    -- INNER JOIN: solo artistas que tienen coincidencia en ambas tablas
WHERE g.rn = 1                    -- nos quedamos solo con el género más frecuente de cada artista
GROUP BY g.genre                   -- agrupamos por género para calcular el promedio por cada uno
ORDER BY promedio_ponderado_oyentes DESC;  





/*CONSULTA 2. NÚMERO DE CANCIONES LANZADAS POR AÑO */

-- Creamos un CTE para calcular el número de canciones por año
WITH canciones_por_anio AS (
    SELECT 
        year AS anio,                -- Seleccionamos el año de lanzamiento
        COUNT(*) AS numero_canciones -- Contamos cuántas canciones se lanzaron en ese año
    FROM canciones
    WHERE year IS NOT NULL           -- Excluimos registros sin año
    GROUP BY year                    -- Agrupamos por año
)

-- Consulta principal
SELECT 
    anio,                             
    numero_canciones,                
    ROUND(AVG(numero_canciones) OVER ()) AS promedio_por_anio -- Calculamos el promedio de canciones por año, redondeado (es solo para comparar)
FROM canciones_por_anio
ORDER BY anio DESC;                   




/* CONSULTA 3: LOS 6 ARTISTAS CON MÁS CANCIONES, SU CANCIÓN MÁS POPULAR Y SU GÉNERO PRINCIPAL
Se identifican los artistas más populares mostrando canciones en base de datos, canción más popular según TopTracks y género principal.
El género principal es el más frecuente en sus canciones.
*/

WITH canciones_por_genero AS (         -- se crea una tabla temporal que cuenta cuántas canciones tiene cada artista por género
    SELECT 
        name_artist,
        genre,
        COUNT(*) AS total_canciones    -- Número de canciones de cada artista por género
    FROM canciones
    GROUP BY name_artist, genre
),
genero_principal AS (
    SELECT 
        name_artist,
        genre,
        ROW_NUMBER() OVER (
            PARTITION BY name_artist            -- Reinicia la numeración por artista
            ORDER BY total_canciones DESC       -- El género con más canciones recibe rn = 1
        ) AS rn
    FROM canciones_por_genero
)
SELECT 
    a.Artist AS artista,
    COUNT(DISTINCT c.name_track) AS total_canciones,   -- Total de canciones únicas
    JSON_UNQUOTE(JSON_EXTRACT(a.TopTracks, '$[0].name')) AS cancion_mas_popular, -- Primera canción de TopTracks
    g.genre AS  genero_principal                        -- Género más frecuente del artista
FROM artistas a
INNER JOIN canciones c
    ON a.Artist = c.name_artist                            -- Relaciona artistas con sus canciones
INNER JOIN genero_principal g
    ON a.Artist = g.name_artist AND g.rn = 1               -- Solo el género principal
GROUP BY a.Artist, g.genre                                 -- Una fila por artista con su género principal
ORDER BY total_canciones DESC                             
LIMIT 6;                                                  



/* 
   CONSULTA 4. TOP 5 CANCIONES MÁS RECIENTES POR ARTISTA COMPARANDO CON LA CANCIÓN MÁS POPULAR (TopTrack)
   Seguimos el criterio de que no se repitan artistas en las canciones más recientes.
   top_track es la primera canción de TopTracks y se compara para análisis de popularidad frente a la canción más reciente.
*/

WITH ranked AS (
    SELECT 
        c.name_track AS cancion,                                  
        c.name_artist AS artista,                                 
        c.genre AS genero,                                        
        c.year AS anio,                                            
        JSON_UNQUOTE(JSON_EXTRACT(a.TopTracks, '$[0].name')) AS top_track,  -- extrae la primera canción de TopTracks (más popular)
        ROW_NUMBER() OVER (
            PARTITION BY c.name_artist                               -- reinicia la numeración para cada artista
            ORDER BY c.year DESC, c.name_track ASC                  -- asigna rn=1 a la canción más reciente, desempate alfabético
        ) AS rn
    FROM canciones c
    INNER JOIN artistas a
        ON c.name_artist = a.Artist                                  -- relaciona cada canción con su artista
)
SELECT 
    cancion, 
    artista, 
    genero, 
    anio, 
    top_track
FROM ranked
WHERE rn = 1                                                       -- solo la canción más reciente por artista
ORDER BY anio DESC                                                   -- ordena las canciones de más reciente a más antigua
LIMIT 5;                                                            -- devuelve las 5 canciones más recientes entre todos los artistas





/* CONSULTA 5. TOP 6 ARTISTAS CON MAYOR NÚMERO DE OYENTES  */
WITH artistas_validos AS (
    -- Solo artistas cuya biografía mencione únicamente los géneros que queremos analizar
    SELECT *
    FROM artistas a
    WHERE a.Biography NOT REGEXP 'Hip-Hop|R&B|Metal|Electro|Folk|Trap|Salsa|Dance|Rap|Tecno'
      AND a.Biography REGEXP 'Pop|Rock|Jazz|Reggaetton'
),

genero_frecuente AS (
    -- Contamos cuántas canciones tiene cada artista por género
    SELECT 
        c.name_artist,         
        c.genre,               
        COUNT(*) AS total_canciones
    FROM canciones c
    INNER JOIN artistas_validos av
        ON c.name_artist = av.Artist   -- solo canciones de artistas válidos
    GROUP BY c.name_artist, c.genre
),

genero_principal AS (
    -- Determinamos el género principal (el más frecuente de cada artista)
    SELECT 
        name_artist,
        genre
    FROM (
        SELECT 
            name_artist,
            genre,
            ROW_NUMBER() OVER (
                PARTITION BY name_artist
                ORDER BY total_canciones DESC
            ) AS rn
        FROM genero_frecuente
    ) t
    WHERE rn = 1
)

-- Consulta principal
SELECT 
    a.Artist AS artista,   
    JSON_UNQUOTE(JSON_EXTRACT(a.TopTracks, '$[0].name')) AS cancion_principal, -- top track
    a.Listeners AS oyentes, 
    g.genre AS genero_principal, -- género más frecuente
    a.Biography AS biografia, 
    CASE
        WHEN a.Biography REGEXP 'United States|USA|U.S.A|American' THEN 'United States'
        WHEN a.Biography REGEXP 'United Kingdom|UK|Britain|British|English' THEN 'United Kingdom'
        WHEN a.Biography REGEXP 'Spain|España' THEN 'Spain'
        WHEN a.Biography REGEXP 'Mexico|México' THEN 'Mexico'
        WHEN a.Biography REGEXP 'France|Francia' THEN 'France'
        WHEN a.Biography REGEXP 'Germany|Deutschland' THEN 'Germany'
        WHEN a.Biography REGEXP 'Italy|Italia' THEN 'Italy'
        WHEN a.Biography REGEXP 'Canada' THEN 'Canada'
        WHEN a.Biography REGEXP 'Brazil|Brasil' THEN 'Brazil'
        WHEN a.Biography REGEXP 'Australia' THEN 'Australia'
        WHEN a.Biography REGEXP 'Korea|Korean' THEN 'South Korea'
        ELSE 'Desconocido'
    END AS pais
FROM artistas_validos a
INNER JOIN canciones c
    ON a.Artist = c.name_artist           -- unimos artista con sus canciones
INNER JOIN genero_principal g
    ON a.Artist = g.name_artist           -- unimos artista con su género principal
GROUP BY 
    a.Artist, g.genre, a.Listeners, a.TopTracks, a.Biography
ORDER BY oyentes DESC
LIMIT 6;

/* NOTA:  
- Ahora el filtrado de géneros se hace con la biografía, excluyendo artistas que mencionen géneros no permitidos.  
- Solo se incluyen artistas “puros” de Pop, Rock, Jazz o Reggaetton o combinaciones entre ellos.  
- La extracción de país sigue usando REGEXP sobre la biografía para identificar nacionalidad o país.  
*/




/* CONSULTA 6. TOP 5 PAÍSES CON MAYOR NÚMERO DE OYENTES 
En este caso, en lugar de utilizar REGEXP, creamos una tabla de referencia de países y palabras clave y después hacemos consultas */
-- Creamos una tabla temporal de países y palabras clave
CREATE TEMPORARY TABLE paises (
    pais VARCHAR(50),
    keyword VARCHAR(50)
);

INSERT INTO paises (pais, keyword) VALUES
('United States', 'United States'),
('United States', 'USA'),
('United States', 'U.S.A'),
('United States', 'American'),
('United States', 'US'),
('United Kingdom', 'United Kingdom'),
('United Kingdom', 'UK'),
('United Kingdom', 'Britain'),
('United Kingdom', 'British'),
('United Kingdom', 'English'),
('United Kingdom', 'England'),
('United Kingdom', 'Great Britain'),
('Spain', 'Spain'),
('Spain', 'España'),
('Spain', 'Español'),
('Mexico', 'Mexico'),
('Mexico', 'México'),
('Mexico', 'Mexican'),
('France', 'France'),
('France', 'Francia'),
('France', 'French'),
('Germany', 'Germany'),
('Germany', 'Deutschland'),
('Germany', 'German'),
('Italy', 'Italy'),
('Italy', 'Italia'),
('Italy', 'Italian'),
('Canada', 'Canada'),
('Canada', 'Canadian'),
('Brazil', 'Brazil'),
('Brazil', 'Brasil'),
('Brazil', 'Brazilian'),
('Australia', 'Australia'),
('Australia', 'Australian'),
('Australia', 'Aus'),
('South Korea', 'Korea'),
('South Korea', 'Korean'),
('South Korea', 'South Korea'),
('South Korea', 'Republic of Korea'),
('Japan', 'Japan'),
('Japan', 'Japanese'),
('Japan', 'Nippon'),
('China', 'China'),
('China', 'Chinese'),
('China', 'PRC'),
('India', 'India'),
('India', 'Indian'),
('India', 'Bharat');

-- Paso 1: sumar listeners por artista para evitar duplicados
WITH artistas_totales AS (
    -- Paso 1: sumar listeners por artista para evitar duplicados
    SELECT
        Artist,
        SUM(Listeners) AS Listeners,
        MAX(Biography) AS Biography  -- tomamos cualquier biografía disponible
    FROM artistas
    GROUP BY Artist
),
artistas_con_pais AS (                    
    -- Paso 2: asignar un solo país por artista
    SELECT
        a.Artist,
        a.Listeners,
        MIN(p.pais) AS pais  
    FROM artistas_totales a
    JOIN paises p
        ON a.Biography LIKE CONCAT('%', p.keyword, '%')
    GROUP BY a.Artist, a.Listeners
)
-- Paso 3: sumar listeners por país
SELECT                                       
    pais,
    SUM(Listeners) AS total_oyentes
FROM artistas_con_pais
GROUP BY pais
ORDER BY total_oyentes DESC
LIMIT 5;




/*CONSULTA 7. TOP DE 3 ARTISTAS CON MÁS DE 3 MILLONES DE OYENTES Y GÉNERO MÚSICAL
 Esta consulta obtiene los 3 artistas más escuchados con más de 3 millones de oyentes,
 mostrando su género principal, pero solo incluyendo artistas “puros” o combinaciones entre Pop, Rock, Jazz y Reggaetton.
 Se filtra mediante la biografía para excluir artistas que mencionen géneros no permitidos.
*/
WITH artistas_validos AS (
    -- Seleccionamos solo artistas que mencionen únicamente los géneros que son objeto de nuestro análisis
    SELECT *
    FROM artistas a
    WHERE a.Biography NOT REGEXP 'Hip-Hop|R&B|Metal|Electro|Folk|Trap|Salsa|Dance|Rap|Tecno'
      AND a.Biography REGEXP 'Pop|Rock|Jazz|Reggaetton'
),

genero_frecuente AS (
    -- Contamos cuántas canciones tiene cada artista por género
    SELECT 
        c.name_artist,
        c.genre,
        COUNT(*) AS total_canciones
    FROM canciones c
    INNER JOIN artistas_validos av
        ON c.name_artist = av.Artist
    GROUP BY c.name_artist, c.genre
),

genero_principal AS (
    -- Determinamos el género principal de cada artista
    SELECT 
        name_artist,
        genre
    FROM (
        SELECT 
            name_artist,
            genre,
            ROW_NUMBER() OVER (
                PARTITION BY name_artist
                ORDER BY total_canciones DESC
            ) AS rn
        FROM genero_frecuente
    ) t
    WHERE rn = 1   -- Solo el género más frecuente
)

SELECT 
    a.Artist AS artista,
    g.genre AS genero_principal,  -- Alias con acento
    a.Listeners AS oyentes
FROM artistas_validos a
INNER JOIN genero_principal g
    ON a.Artist = g.name_artist
WHERE a.Listeners > 3000000
ORDER BY oyentes DESC
LIMIT 3;




/* 
   CONSULTA 8. TOP 4 ARTISTAS CON MÁS GÉNEROS DISTINTOS, ORDENADOS POR NÚMERO DE OYENTES
   - Solo se incluyen artistas “puros” o combinaciones de Pop, Rock, Jazz y Reggaetton.
   - Se filtra mediante la biografía para excluir géneros que no son objeto de nuestro análisis.
*/

WITH artistas_validos AS (  -- tabla temporal que filtra solo los artistas válidos
    SELECT *
    FROM artistas a
    WHERE a.Biography NOT REGEXP 'Hip-Hop|R&B|Metal|Electro|Folk|Trap|Salsa|Dance|Rap|Tecno'
      AND a.Biography REGEXP 'Pop|Rock|Jazz|Reggaetton'
)

SELECT 
    c.name_artist AS artista,
    GROUP_CONCAT(DISTINCT c.genre ORDER BY c.genre ASC) AS generos,  -- lista de géneros distintos
    COUNT(DISTINCT c.genre) AS total_generos,                        -- número de géneros distintos
    a.Listeners AS oyentes
FROM canciones c
INNER JOIN artistas_validos a  -- se une la tabla temporal de artistas válidos
    ON c.name_artist = a.Artist
GROUP BY c.name_artist, a.Listeners
ORDER BY total_generos DESC, oyentes DESC
LIMIT 4;




/* 9. CANCIONES CON MAYOR NÚMERO DE OYENTES EN CADA UNO DE LOS AÑOS DE 2019 A 2024 CON ARTISTA Y GÉNERO */
-- Solo queremos canciones de los 4 géneros puros: Pop, Rock, Jazz o Reggaeton, o combinaciones entre ellos.
-- No incluimos combinaciones con géneros que no están permitidos.

-- CTE (tabla temporal) para filtrar solo artistas válidos
WITH artistas_validos AS (
    SELECT *
    FROM artistas a
    -- Excluimos artistas que mencionen géneros que no son los que estamos analizando
    WHERE a.Biography NOT REGEXP 'Hip-Hop|R&B|Metal|Electro|Folk|Trap|Salsa|Dance|Rap|Tecno'
      -- Incluimos solo artistas que mencionen al menos uno de los géneros objeto de análisis
      AND a.Biography REGEXP 'Pop|Rock|Jazz|Reggaetton'
),

-- CTE (tabla temporal) para seleccionar solo canciones de los artistas válidos
canciones_filtradas AS (
    SELECT
        c.name_track AS cancion,                        
        c.name_artist AS artista,                       
        c.year AS anio,                                  
        GROUP_CONCAT(DISTINCT c.genre ORDER BY c.genre ASC) AS genero,  -- Combinación de géneros de la canción
        a.Listeners AS oyentes                         -- Número de oyentes del artista
    FROM canciones c
    INNER JOIN artistas_validos a
        ON c.name_artist = a.Artist                     -- Solo canciones de artistas válidos
    WHERE c.year BETWEEN 2019 AND 2024                 -- Filtramos los años de interés
    GROUP BY c.name_track, c.name_artist, c.year, a.Listeners
),

-- CTE (tabla temporal) para asignar ranking por oyentes dentro de cada año
canciones_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY anio                              -- Reinicia el ranking por cada año
            ORDER BY oyentes DESC, cancion ASC          -- Ordena por oyentes (mayor primero), desempate por nombre de canción
        ) AS rn
    FROM canciones_filtradas
)

-- Consulta final: selecciona la canción más escuchada de cada año
SELECT 
    cancion, 
    artista, 
    anio, 
    genero
FROM canciones_ranked
WHERE rn = 1
ORDER BY anio ASC;












