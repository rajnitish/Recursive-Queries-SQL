--PREAMBLE--

--1--						   
WITH recursive mytable AS 
( 
       SELECT destination 
       FROM   trainschedule 
       WHERE  source = 'Delhi' 
       UNION 
       SELECT     e.destination 
       FROM       trainschedule e 
       INNER JOIN mytable s 
       ON         s.destination = e.source ) 
SELECT   destination 
FROM     mytable 
ORDER BY destination;
--2--
WITH recursive mytable AS 
( 
       SELECT train_id, 
              destination, 
              arrival_time, 
              departure_time, 
              0 AS depth 
       FROM   trainschedule 
       WHERE  source = 'Delhi' 
       UNION 
       SELECT     e.train_id, 
                  e.destination, 
                  e.arrival_time , 
                  e.departure_time, 
                  0 AS depth 
       FROM       trainschedule e 
       INNER JOIN mytable 
       ON         e.source = mytable.destination 
       AND 
                  CASE 
                             WHEN ( 
                                                   e.departure_time - mytable.arrival_time) >= '00:00:00' THEN (e.departure_time - mytable.arrival_time) <= '01:00:00'
                             ELSE (e.departure_time                 - mytable.arrival_time) + '24:00:00' <= '01:00:00'
                  END ) 
SELECT DISTINCT destination 
FROM            mytable 
ORDER BY        destination;
--3--
WITH recursive mytable AS 
( 
       SELECT train_id, 
              source, 
              destination, 
              arrival_time, 
              departure_time, 
              0 AS depth, 
              CASE 
                     WHEN ( 
                                   arrival_time - departure_time) >= '00:00:00' THEN (arrival_time - departure_time)
                     ELSE (arrival_time         - departure_time) + '24:00:00' 
              END AS duration 
       FROM   trainschedule 
       WHERE  source = 'Delhi' 
       UNION 
       SELECT     mytable.train_id, 
                  mytable.source, 
                  e.destination, 
                  e.arrival_time, 
                  e.departure_time, 
                  0 AS depth, 
                  CASE 
                             WHEN ( 
                                                   e.departure_time - mytable.arrival_time) >= '00:00:00' THEN mytable.duration + (e.arrival_time - mytable.arrival_time)
                             ELSE mytable.duration + (e.arrival_time - mytable.arrival_time) + '24:00:00'
                  END 
       FROM       trainschedule e 
       INNER JOIN mytable 
       ON         mytable.destination = e.source ) 
SELECT min(duration) AS shortest_time 
FROM   mytable 
WHERE  destination = 'Mumbai' limit 1;
--4--
WITH recursive mytable AS 
( 
       SELECT train_id, 
              destination 
       FROM   trainschedule 
       WHERE  source = 'Delhi' 
       UNION 
       SELECT     e.train_id, 
                  e.destination 
       FROM       trainschedule e 
       INNER JOIN mytable s 
       ON         s.destination = e.source ) 
SELECT   * 
FROM     ( 
                SELECT train_id 
                FROM   trainschedule 
                EXCEPT 
                SELECT train_id 
                FROM   mytable) AS lltk 
ORDER BY 1;
--5--
WITH recursive mytable AS 
( 
       SELECT train_id, 
              source, 
              destination, 
              0 AS depth, 
              CASE 
                     WHEN ( 
                                   arrival_time - departure_time) >= '00:00:00' THEN (arrival_time - departure_time)
                     ELSE (arrival_time         - departure_time) + '24:00:00' 
              END AS journey_time 
       FROM   trainschedule 
       UNION 
       SELECT     mytable.train_id, 
                  mytable.source, 
                  e.destination, 
                  0 AS depth, 
                  CASE 
                             WHEN ( 
                                                   e.arrival_time - e.departure_time) >= '00:00:00' THEN (e.arrival_time - e.departure_time)
                             ELSE (e.arrival_time                 - e.departure_time) + '24:00:00'
                  END AS journey_time 
       FROM       trainschedule e 
       INNER JOIN mytable 
       ON         mytable.destination = e.source 
       AND 
                  CASE 
                             WHEN ( 
                                                   e.arrival_time         - e.departure_time) >= '00:00:00' THEN mytable.journey_time <= (e.arrival_time - e.departure_time)
                             ELSE mytable.journey_time <= (e.arrival_time - e.departure_time) + '24:00:00'
                  END ) 
SELECT DISTINCT source, 
                destination 
FROM            mytable 
ORDER BY        source, 
                destination;
--6--
WITH recursive mainreturn AS ( WITH recursive basecond AS 
( 
       SELECT source, 
              destination, 
              arrival_time - departure_time AS timetaken , 
              0                             AS depth 
       FROM   trainschedule 
       UNION 
       SELECT     e.source, 
                  e.destination, 
                  e.arrival_time - e.departure_time, 
                  basecond.depth + 1 
       FROM       trainschedule e 
       INNER JOIN basecond 
       ON         e.source = basecond.destination ) 
SELECT * 
FROM   basecond 
WHERE  depth = 0 
UNION 
SELECT k.source, 
       m.destination, 
       m.timetaken , 
       m.depth 
FROM   mainreturn k , 
       basecond l , 
       basecond m 
WHERE  ( 
              k.destination = l.source 
       AND    l.destination = m.source 
       AND    k.timetaken >= m.timetaken 
       AND    k.depth % 2 = 0 
       AND    m.depth - k.depth = 2 ) 
OR     ( 
              k.destination = m.source 
       AND    k.depth % 2 = 0 
       AND    k.depth + 1 = m.depth ) ) 
SELECT   source, 
         destination 
FROM     mainreturn 
GROUP BY source, 
         destination 
ORDER BY source, 
         destination;
--7--
SELECT * 
FROM   ( ( WITH notreachable AS 
       ( 
              SELECT source AS city 
              FROM   trainschedule 
              UNION 
              SELECT destination AS city 
              FROM   trainschedule )SELECT DISTINCT e.city       AS source, 
                f.city       AS destination 
FROM            notreachable AS e, 
                notreachable AS f 
WHERE           e.city <> f.city ) 
EXCEPT 
       ( WITH recursive mytable AS 
       ( 
              SELECT source, 
                     destination 
              FROM   trainschedule 
              UNION 
              SELECT     mytable.source, 
                         e.destination 
              FROM       trainschedule AS e 
              INNER JOIN mytable 
              ON         mytable.destination = e.source )SELECT   * 
FROM     mytable ) ) AS tb11 
ORDER BY source, 
         destination;
--8--
WITH recursive mytable AS 
( 
       SELECT source, 
              destination, 
              source 
                     || destination AS path, 
              0                     AS depth 
       FROM   trainschedule 
       WHERE  source = 'Delhi' 
       UNION 
       SELECT     mytable.destination, 
                  e.destination, 
                  mytable.path 
                             ||    e.destination, 
                  0             AS depth 
       FROM       trainschedule e 
       INNER JOIN mytable 
       ON         mytable.destination = e.source ) 
SELECT count(*) AS no_of_paths 
FROM   mytable 
WHERE  destination = 'Mumbai';
--9--
WITH recursive mytable AS 
( 
       SELECT source, 
              destination , 
              0 AS depth 
       FROM   trainschedule 
       WHERE  source = 'Delhi' 
       UNION 
       SELECT     mytable.source, 
                  e.destination , 
                  0 AS depth 
       FROM       trainschedule e 
       INNER JOIN mytable 
       ON         mytable.destination = e.source ) 
SELECT DISTINCT destination AS cities_havingexactly_onepath 
FROM            mytable 
GROUP BY        destination 
HAVING          count(*) = 1 
ORDER BY        destination;
--10--
WITH recursive mytable AS 
( 
       SELECT train_id, 
              source , 
              destination, 
              source 
                     || destination AS path, 
              0                     AS depth 
       FROM   trainschedule 
       UNION 
       SELECT     e.train_id, 
                  mytable.source, 
                  e.destination, 
                  mytable.path 
                             ||    e.destination, 
                  0             AS depth 
       FROM       trainschedule AS e 
       INNER JOIN mytable 
       ON         mytable.destination = e.source ) 
SELECT countdb * countbh 
FROM   ( 
              SELECT count(*) AS countdb, 
                     0        AS depth 
              FROM   mytable 
              WHERE  source = 'Delhi' 
              AND    destination = 'Bhopal' )delhitobhopal, 
       ( 
              SELECT count(*) AS countbh, 
                     0        AS depth 
              FROM   mytable 
              WHERE  source = 'Bhopal' 
              AND    destination = 'Hyderabad' ) bhopaltohyderabad;
--CLEANUP--
