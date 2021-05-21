-- AGREGAR COLUMNAS A LA RED VIAL NECESARIAS PARA EL PGROUTING
alter table redpeatonal_univalle add column x1 double precision;
alter table redpeatonal_univalle add column y1 double precision;
alter table redpeatonal_univalle add column x2 double precision;
alter table redpeatonal_univalle add column y2 double precision;
alter table redpeatonal_univalle add column source integer;
alter table redpeatonal_univalle add column target integer;
alter table redpeatonal_univalle add column costo double precision;

<-- Completar los atributos que se acabaron de crear

-- de tipo linea y un parametro N, y retorna el N-esimo punto de -- la linea
-- st_linemerge: unión que sin considerar el orden de los vértices, devuelve una cadena de líneas donde las líneas se unen topológicamente.
-- PointN: Recibe una geometria e indica la posicion del punto por eso el 1 esta en la sentencia.
-- st_x:   Permite retornar la coordenada x asociada de un punto
-- st_numpoints: retorna el numero (entero) de puntos o nodos de una linea 

-- CALCULO DE COORDENADA DEL PUNTO INICIAL
UPDATE redpeatonal_univalle set x1 = st_x(st_pointn(st_linemerge(the_geom),1));
UPDATE redpeatonal_univalle set y1 = st_y(st_pointn(st_linemerge(the_geom),1));


-- CALCULO DE COORDENADA DEL PUNTO FINAL
UPDATE redpeatonal_univalle set x2 = st_x(st_pointn(st_linemerge(the_geom),st_numpoints(st_linemerge(the_geom))));
UPDATE redpeatonal_univalle set y2 = st_y(st_pointn(st_linemerge(the_geom),st_numpoints(st_linemerge(the_geom))));


-- CREAR LA TOPOLOGIA - Calcular el source y tarjet para cada punto 

SELECT pgr_createTopology('redpeatonal_univalle',0.00001, 'the_geom', 'gid');
-- Calcular los nodos de inicio y final con ayuda de las extension de pgrouting
-- Crea una tabla adicional de tipo punto que son los nodos, y adicionalmente
-- se actualizan las columnas "source" y "target" de la capa de red vial 
-- entrada a la funcion pgr_createTopology
-- 0.00001 tolerancia topologica 


-- CREACION DE INDICES espaciales sobre el atributo de source y target

   --Los indices hacen que sea mas eficiente las operaciones del pgrouting
   --La indexación acelera la búsqueda al organizar los datos rápidamente para encontrar un registro en particular.
create index indice_source on redpeatonal_univalle("source");
create index indice_target on redpeatonal_univalle("target");


-- CALCULAR EL COSTO que es igual a la longitud de cada segmento, haciendo transformacion al vuelo con st_transform
   UPDATE redpeatonal_univalle set costo = st_length(st_transform(the_geom,3115));


-- CALCULO DE RUTA MAS CORTA ENTRE DOS NODOS,
   --se usa el algotitmo de ruteo de pgrouting llamado pgr_dijkstra 
   --que busca el camino mas corto desde el vertice de origen hacia el resto de nodos

select seq, id1 as node, id2 as edge, cost from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle',
	651,2195,false,false);

-- VISUALIZAR LA RUTA EN UNA VISTA 
	CREATE OR REPLACE VIEW resultado_ruteo AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle',
	651,2147,false,false) a
	left join redpeatonal_univalle b on (a.id2 = b.gid);
	
-- ALTERAR EL COSTO DE UN NODO 
	update redpeatonal_univalle set costo=100 where gid=1006;
	
	

-------------------------------------------------- TALLER RUTEO -------------------------------------------------------------------

-- 3. REALIZAR CALCULO RUTA MÁS CORTA ENTRE PUNTO INICIAL DADO POR COORDENADAS (LAT,LON) Y UN NODO

-- Primero: identificar de toda la malla de puntos cual está mas cerca a la coordenada de interes.
--          Para ello creamos primero el punto con st_point, st_makepoint o st_GeometryFromText ('POINT(-76.53487,3.37284)')


	CREATE OR REPLACE VIEW punto3 AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle',
	
	(  select corto.id::integer from
	   (select nodos.id,   
	   st_distance (ST_SetSRID (st_makepoint(-76.53485,3.37275),4326),nodos.the_geom) as distancia
	   from redpeatonal_univalle_vertices_pgr as nodos
	   order by distancia asc limit 1) as corto
	),1788,false,false) a
	left join redpeatonal_univalle b on (a.id2 = b.gid);
	
	
-- 4. REALIZAR CALCULO RUTA MÁS CORTA ENTRE PUNTO INICIAL DADO POR COORDENADAS (LAT,LON)
--     Y PUNTO FINAL DADO POR COORDENADAS (LAT,LON)

	CREATE OR REPLACE VIEW punto4 AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle',
	
	(  select corto.id::integer from
	   (select nodos.id,   
	   st_distance (ST_SetSRID (st_makepoint(-76.53485,3.37275),4326),nodos.the_geom) as distancia
	   from redpeatonal_univalle_vertices_pgr as nodos
	   order by distancia asc limit 1) as corto
	),
	
	( select corto.id::integer from
	   (select nodos.id,   
	   st_distance (ST_SetSRID (st_makepoint(-76.53095,3.37315),4326),nodos.the_geom) as distancia
	   from redpeatonal_univalle_vertices_pgr as nodos
	   order by distancia asc limit 1) as corto
	   
	),false,false) a left join redpeatonal_univalle b on (a.id2 = b.gid);


-- 5. REALIZAR CALCULO RUTA MÁS CORTA ENTRE PUNTO INICIAL DADO POR COORDENADAS (X,Y) Y 
--    PUNTO FINAL DADO POR COORDENADAS (LAT,LON). NOTA: X,Y EN 3115

	CREATE OR REPLACE VIEW punto5 AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle', 
	(select corto.id::integer from
		(select nodos.id,   
		st_distance(ST_Transform(ST_SetSRID(st_makepoint(1060066.405,865433.078),3115),4326), nodos.the_geom) as distancia from redpeatonal_univalle_vertices_pgr as nodos
		order by distancia asc limit 1) as corto),
	(select corto.id::integer from
		(select nodos.id,   
		st_distance (ST_SetSRID (st_makepoint(-76.53485,3.37275),4326),nodos.the_geom) as distancia
		from redpeatonal_univalle_vertices_pgr as nodos
		order by distancia asc limit 1) as corto),
		false,false) a left join redpeatonal_univalle b on (a.id2 = b.gid);

	
	
-- 6.PARA REALIZAR CALCULO ENTRE UN PUNTO INICIAL DADO POR COORDENADAS (LAT,LON) Y 
--    UN SITIO DE INTERÉS (BUSCAR EL NODO MÁS CERCANO)
	
	CREATE OR REPLACE VIEW punto6 AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle', 
	(select corto.id::integer from
	   (select nodos.id,   
		st_distance (ST_SetSRID (st_makepoint(-76.53485,3.37275),4326),nodos.the_geom) as distancia
		from redpeatonal_univalle_vertices_pgr as nodos
		order by distancia asc limit 1) as corto),
	(select corto.id::integer from
	   (select nodos.id,   
		st_distance ((select the_geom from sitiosinteres_univalle where name like 'Comidas%'),nodos.the_geom) as distancia
		from redpeatonal_univalle_vertices_pgr as nodos
		order by distancia asc limit 1) as corto),
		false,false) a left join redpeatonal_univalle b on (a.id2 = b.gid);

	
-- 7. Calcular la Ruta más corta entre el CAI y la plazoleta de Ingeniería
	
	CREATE OR REPLACE VIEW punto7 AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle', 
	(select corto.id::integer from
		(select nodos.id,   
		st_distance ((select the_geom from sitiosinteres_univalle where name like 'Plazoleta% de Ingenier%'),nodos.the_geom) as distancia from redpeatonal_univalle_vertices_pgr as nodos order by distancia asc limit 1) as corto),
	(select corto.id::integer from
		(select nodos.id,   
		st_distance ((select the_geom from sitiosinteres_univalle where name like 'CAI%'),nodos.the_geom) as distancia from redpeatonal_univalle_vertices_pgr as nodos order by distancia asc limit 1) as corto),
		false,false) a left join redpeatonal_univalle b on (a.id2 = b.gid);

	

-- 8. (a) Calcular la ruta entre el punto -76.53427,3.37408 y el punto -76.53231,3.37677

	CREATE OR REPLACE VIEW punto8a AS 
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra('
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle',
	
	(select corto.id::integer from
	  (select nodos.id,   
	  st_distance (ST_SetSRID (st_makepoint(-76.53427,3.37408),4326),nodos.the_geom) as distancia
	  from redpeatonal_univalle_vertices_pgr as nodos
	  order by distancia asc limit 1) as corto),
	
	(select corto.id::integer from
	  (select nodos.id,   
	  st_distance (ST_SetSRID (st_makepoint(-76.53231,3.37677),4326),nodos.the_geom) as distancia
	  from redpeatonal_univalle_vertices_pgr as nodos
	  order by distancia asc limit 1) as corto),
																			
	false,false) a left join redpeatonal_univalle b on (a.id2 = b.gid);
	

--    (b) Incrementar en un 10% el costo de los segmentos de red peatonal que se encuentran 
--        a un radio de 120 metros 

	UPDATE redpeatonal_univalle
	SET costo = costo*1.10
	WHERE st_intersects(the_geom, st_transform(st_buffer(st_transform(st_setSRID(st_MakePoint(-76.53322,3.37537), 4326), 3115),120), 4326))= 't'

	CREATE OR REPLACE VIEW punto8c AS
	SELECT 1 AS gid, st_transform(st_buffer(st_transform(st_setSRID(st_MakePoint(-76.53322,3.37537), 4326), 3115),120), 4326)


--    (d) Reversar los cambios de costo. 
	UPDATE redpeatonal_univalle SET costo= longitud

