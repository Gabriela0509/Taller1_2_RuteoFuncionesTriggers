-- 1. TABLA-----------------------------------------------------------------------------
DROP TABLE IF EXISTS informacion_edificio;
CREATE TABLE informacion_edificio
(
	gid serial PRIMARY KEY, 
	x double precision, 
	y double precision, 
	
	edifcercano_id varchar(150), 
	edifcercano_nombre varchar(150),/*nombreedificio_identificador*/
	edifcercano_dist double precision,
	
	sitiocercano_id varchar(150), /*sitiointeres_cercano_id*/
	sitiocercano_dist double precision,/*sitiointeres_cercano_distancia*/
	
	sitiolejano_id varchar(150), 
	sitiolejano_dist double precision,
	
	azimut double precision,
	/*puntomedio geometry (POINT,4326)*/
	pm_x double precision, 
	pm_y double precision, 
	distancia double precision,
	the_geom geometry (POINT,4326)
);

--Consulta-----------------------------------------------------------------------------

-- 0. Crear punto x,y
UPDATE informacion_edificio SET x= st_x(the_geom), y=st_y(the_geom)

-- 1. El Identificador, nombre y distancia al edificio más cercano
UPDATE informacion_edificio SET 
edifcercano_id = 
	(select a.osm_id from 
	(SELECT osm_id, name, 
	st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
	FROM edificios_univalle ORDER BY dist ASC LIMIT 1) as a),
 
edifcercano_nombre=
	(select b.name from 
	(SELECT osm_id, name, 
	st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
	FROM edificios_univalle ORDER BY dist ASC LIMIT 1) as b),

edifcercano_dist=
	(select c.dist from 
	(SELECT osm_id, name, 
	st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
	FROM edificios_univalle ORDER BY dist ASC LIMIT 1) as c);


-- 2. El Identificador y distancia al sitio de interes más cercano*/
UPDATE informacion_edificio SET 
sitiocercano_id=
	(select a.osm_id from 
	(SELECT osm_id, name, 
	st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
	FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as a),
	
sitiocercano_dist=
	(select b.dist from 
	(SELECT osm_id, name, 
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b);
	
-- 3. El Identificador y distancia al sitio de interes más lejano*/
UPDATE informacion_edificio SET 
sitiolejano_id=
	(select a.osm_id from 
	(SELECT osm_id, name, 
	st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
	FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as a),
	
sitiolejano_dist=
	(select b.dist from 
	(SELECT osm_id, name, 
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b);
	
	
-- 4. El azimut comprendido entre el sitio de interés más cercano y el más lejano.
UPDATE informacion_edificio SET 
azimut= 
	(select degrees (st_azimuth(
	(select b.the_geom from 
	(SELECT osm_id,the_geom, name, 
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b),
	(select b.the_geom from 
	(SELECT osm_id, name, the_geom,
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b))));
 
-- 5. no se hizo para no duplicar el the_geom . El punto medio (geometría) comprendido entre el sitio de interés más lejano y el más cercano.

-- 6. Las coordenadas (en 3115) del punto medio comprendido entre el sitio de interés más lejano y el más cercano.
UPDATE informacion_edificio SET 
pm_x= (select (
	st_x ((select st_transform (b.the_geom,3115) from 
	(SELECT the_geom, 
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b)) +
	st_x((select b.the_geom from 
	(SELECT the_geom,
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b)))/2),

pm_y= (select (
	st_y ((select st_transform(b.the_geom,3115) from 
	(SELECT the_geom, 
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b)) +
	st_y((select b.the_geom from 
	(SELECT the_geom,
	st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b)))/2);

-- 7. La distancia euclidiana entre el sitio de interés más cercano y el más lejano.
	
UPDATE informacion_edificio SET 
distancia= (select st_distance(

	(select st_transform (b.the_geom,3115) from 
	(SELECT the_geom, st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b),
	
	(select st_transform (b.the_geom,3115) from 
	(SELECT the_geom, st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
	FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b)));
	
--2.FUNCION-------------------------------------------------------------------

CREATE OR REPLACE FUNCTION funcion_taller2_trigger()
RETURNS TRIGGER AS $$

	BEGIN 

	NEW.x= st_x(new.the_geom);
	NEW.y= st_y(new.the_geom);
	NEW.edifcercano_id = 
		(select a.osm_id from 
		(SELECT osm_id, name, 
		st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
		FROM edificios_univalle ORDER BY dist ASC LIMIT 1) as a);

	NEW.edifcercano_nombre=
		(select b.name from 
		(SELECT osm_id, name, 
		st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
		FROM edificios_univalle ORDER BY dist ASC LIMIT 1) as b);

	NEW.edifcercano_dist=
		(select c.dist from 
		(SELECT osm_id, name, 
		st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
		FROM edificios_univalle ORDER BY dist ASC LIMIT 1) as c);

	NEW.sitiocercano_id=
		(select a.osm_id from 
		(SELECT osm_id, name, 
		st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
		FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as a);

	NEW.sitiocercano_dist=
		(select b.dist from 
		(SELECT osm_id, name, 
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b);

	NEW.sitiolejano_id=
		(select a.osm_id from 
		(SELECT osm_id, name, 
		st_distance(the_geom,st_setsrid(st_makepoint(-76.5675,3.37263),4326)) as dist
		FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as a);

	NEW.sitiolejano_dist=
		(select b.dist from 
		(SELECT osm_id, name, 
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b);
	
--------------------------------
/*NEW.puntomedio=
		(SELECT (st_centroid(st_makeline((SELECT the_geom FROM sitiosinteres_univalle WHERE osm_id= NEW.sitiocercano_id),
		(SELECT the_geom FROM sitiosinteres_univalle WHERE osm_id=NEW.sitiolejano_id ))))
		FROM sitiosinteres_univalle);
*/
-------------------------

	NEW.azimut= 
		(select degrees (st_azimuth(
		(select b.the_geom from 
		(SELECT osm_id,the_geom, name, 
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b),
		(select b.the_geom from 
		(SELECT osm_id, name, the_geom,
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b))));

	NEW.pm_x= 
		(select (st_x ((select st_transform (b.the_geom,3115) from 
		(SELECT the_geom, 
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b)) +
		st_x((select b.the_geom from 
		(SELECT the_geom,
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b)))/2);

	NEW.pm_y= 
		(select (st_y ((select st_transform(b.the_geom,3115) from 
		(SELECT the_geom, 
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b)) +
		st_y((select b.the_geom from 
		(SELECT the_geom,
		st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b)))/2);

	NEW.distancia= 
		(select st_distance(
		(select st_transform (b.the_geom,3115) from 
		(SELECT the_geom, st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist ASC LIMIT 1) as b),

		(select st_transform (b.the_geom,3115) from 
		(SELECT the_geom, st_distance(st_transform(the_geom,3115),st_transform(st_setsrid(st_makepoint(-76.5675,3.37263),4326),3115)) as dist
		FROM sitiosinteres_univalle ORDER BY dist DESC LIMIT 1) as b)));

		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

--3. TRIGGER----------------------------------------------------------------------

DROP TRIGGER trigger_taller2 on informacion_edificio


CREATE TRIGGER trigger_taller2
  BEFORE INSERT OR UPDATE
  ON informacion_edificio
  FOR EACH ROW
EXECUTE PROCEDURE funcion_taller2_trigger();


--4. INGRESAR PARAMETROS----------------------------------------------------------

insert into informacion_edificio (the_geom) values (st_setsrid(st_makepoint(-76.654,3.5134),4326))


--OTROS------------------------------------------------------------------------
INSERT into informacion_edificio values (-76.53509,3.37263);
INSERT into informacion_edificio(-77.53509,3.37263); values (-77.53509,3.37263);
SELECT degrees(ST_Azimuth((SELECT the_geom FROM sitiosinteres_univalle WHERE osm_id='2206916348'),(SELECT the_geom FROM sitiosinteres_univalle WHERE osm_id='2206891349')))

