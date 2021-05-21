------------------------------------TALLER FUNCIONES --------------------------------------------------------------------------

-- 1. CONSTRUIR UNA FUNCIÓN PARA VERIFICAR SI UNA PALABRA ES UN PALÍNDROMO

CREATE OR REPLACE FUNCTION ESPalindromo(Texto text) RETURNS text AS $$
	DECLARE
	BEGIN
		IF  LOWER(REPLACE(Texto, ' ','')) =  LOWER(REVERSE(REPLACE(Texto, ' ',''))) THEN
			RETURN 'La palabra: ' || Texto || ' ES un Palíndromo';
		ELSE
			RETURN 'La palabra: ' || Texto || ' NO es un Palíndromo';
		END IF;
	END;	
$$ LANGUAGE plpgsql


SELECT ESPalindromo('Luz Azul')
SELECT ESPalindromo('Anita lava la tina')
SELECT ESPalindromo('raza')



-- 2. Construir funcion que permita convertir coordenadas DMS a DEG

CREATE OR REPLACE FUNCTION convertir_DMSaDEG(double precision, double precision, double precision)
RETURNS double precision AS $$ /*Tipo de datos que retornará*/
DECLARE /*Parametros*/
	D ALIAS FOR $1;
	M ALIAS FOR $2;
	S ALIAS FOR $3;
BEGIN /*codigo funion*/
	if D>90 or M>60 or S>60 then raise notice 'Verifique los parámetros ingresados';
	else return D+M/60+S/3600::double precision; 
	end if;
END
$$ LANGUAGE plpgsql;

select convertir_DMSaDEG(50,50,50)
select convertir_DMSaDEG(100,70,70)


-- 3. Crear una funcion que permita calcular ruta más corta entre 2 nodos: 

CREATE OR REPLACE FUNCTION RutaCortaNodos(integer, integer, text) 

	RETURNS text AS $$
	DECLARE
	Nodo1 alias for $1;
	Nodo2 alias for $2;
	rutaNodosCorta  alias for $3;
	BEGIN
		EXECUTE 'CREATE OR REPLACE VIEW '||rutaNodosCorta||' AS (select seq, id1 as node,
		id2 as edge, cost, b.the_geom from pgr_dijkstra(''SELECT gid as id,
		source::integer,
		target::integer,
		costo::double precision as cost
		from redpeatonal_univalle'','||Nodo1||','||Nodo2||',false,false) a
		left join redpeatonal_univalle b on (a.id2 = b.gid));';
		RETURN 'la vista se creó con exito';
	END;
$$ LANGUAGE plpgsql;

SELECT RutaCortaNodos(760, 2020, 'CortaNodos1')



--4. FUNCION QUE PERMITA CALCULAR RUTA MÁS CORTA ENTRE 2 COORDENADAS:  

CREATE OR REPLACE FUNCTION RutaCortaCoordenadas(double precision, double precision, double precision, double precision, text)
RETURNS void AS $$
DECLARE
	latitud1 alias for $1;
	longitud1 alias for $2;
	latitud2 alias for $3;
	longitud2 alias for $4;
	rutaCoordCorta alias for $5;

	BEGIN
	EXECUTE 'CREATE OR REPLACE VIEW '||rutaCoordCorta||' AS (
	SELECT seq, id1 AS node,id2 AS edge, cost, b.the_geom from pgr_dijkstra(''
	select gid as id,
	source::integer,
	target::integer,
	costo::double precision as cost
	from redpeatonal_univalle'',
	  (select corto.id::integer from
	  (select nodos.id,  
	  st_distance (ST_SetSRID (st_makepoint('||longitud1||','||latitud1||'),4326),nodos.the_geom) as distancia
	  from redpeatonal_univalle_vertices_pgr as nodos
	  order by distancia asc limit 1) as corto),

	  (select corto.id::integer from
	  (select nodos.id,  
	  st_distance (ST_SetSRID (st_makepoint('||longitud2||','||latitud2||'),4326),nodos.the_geom) as distancia
	  from redpeatonal_univalle_vertices_pgr as nodos
	  order by distancia asc limit 1) as corto), false,false) a left join redpeatonal_univalle b on (a.id2 = b.gid));';
	END;
$$ LANGUAGE plpgsql;


select RutaCortaCoordenadas(3.37275,-76.53485,3.37272,-76.53297,'resultado_punto3B');



