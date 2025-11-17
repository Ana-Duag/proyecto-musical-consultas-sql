# Proyecto Music Stream. Popularidad de Canciones en la Era Digital.

## Descripción

### Este proyecto ha sido desarrollado por **Ana Dueñas** ,Adalab, Septiembre 2025.

Consiste en la extracción y análisis de datos musicales obtenidos a partir de las APIs de Spotify y Last.FM.

Se extrajeron datos de artistas y canciones mediante las APIs.

Los datos se transformaron en dataframes y posteriormente se volcaron en una base de datos SQL (music_stream_proyecto).

Se realizaron distintas consultas SQL para analizar artistas, géneros musicales, canciones y oyentes.

Se trabajó  con las tablas:

- artistas

- canciones

---


## Consultas realizadas

### Consulta 1: Promedio de oyentes de cada género

Se utiliza el género principal de cada artista y se pondera por número de canciones para mayor realismo.


### Consulta 2: Número de canciones lanzadas por año

Muestra cuántas canciones se publicaron por año.

Incluye también el promedio global por año.


### Consulta 3: Top 6 artistas con más canciones en la Base de Datos, canción más popular y género principal


### Consulta 4: Top 5 canciones más recientes por artista

Devuelve las canciones más nuevas, comparando con el Top Track de cada artista.


### Consulta 5: Top 6 artistas con mayor número de oyentes en los géneros analizados, se incluye biografía y país



### Consulta 6: Top 5 países con mayor número de oyentes

Se crea una tabla temporal con países y palabras clave.

Se suman oyentes por país.


### Consulta 7: Top 3 artistas con más de 3M de oyentes

Solo se incluyen artistas de los 4 géneros principales que estamos analizando.

Se muestran sus géneros principales.


### Consulta 8: Top 4 artistas con más géneros distintos

Se identifican los artistas con mayor diversidad de géneros musicales.


### Consulta 9: Canciones más escuchadas por año (2019–2024)

Se selecciona la canción con más oyentes en cada año.

Solo se incluyen los 4 géneros que queremos analizar o combinaciones entre ellos.

---

## Tecnologías usadas

Python (extracción desde APIs, creación de dataframes).

MySQL (volcado de datos y consultas).

Git y GitHub (control de versiones).

---

## Presentación del Proyecto (Genially)

[Ver presentación](https://view.genially.com/68c08cbeff8b74cf1f73f4c2/presentation-go)