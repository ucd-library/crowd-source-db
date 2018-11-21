CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA public;
COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';
--CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA public;
--COMMENT ON EXTENSION pgtap IS 'Unit testing for PostgreSQL';

--DROP SCHEMA catalogs cascade;
CREATE SCHEMA crowd_source;
SET search_path = crowd_source,public,pg_catalog;
alter database :DBNAME set search_path to crowd_source,public,pg_catalog;

CREATE TABLE collections (
    collection_id text primary key,
    name text,
    description text
);

CREATE TABLE items (
    item_id text primary key,
    collection_id text references collections not null,
    parent_id text references items,
    editable boolean default true,
    completed boolean default false,
    index integer
);
create index on items(collection_id);
create index on items(parent_id);
create index on items(index);

CREATE TABLE crowd_inputs (
   crowd_input_id uuid primary key default public.gen_random_uuid(),
   user_id text,
   item_id text REFERENCES items not null,
   anonymous boolean,
   data json not null,
   created timestamp without time zone,
   updated timestamp without time zone
);
create index on crowd_inputs(user_id);

CREATE TABLE suggest (
   suggest_id uuid primary key default public.gen_random_uuid(),
   collection_id text REFERENCES collections not null,
   type text not null,
   text text not null,
   tsv tsvector
);
create unique index idx_suggest_unique on suggest(collectionId, type, text);

CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
ON suggest FOR EACH ROW EXECUTE PROCEDURE
tsvector_update_trigger(tsv, 'pg_catalog.english', text);

CREATE TABLE users (
    user_id text primary key,
    score integer
);

CREATE FUNCTION crowd_inputs(items) RETURNS bigint AS $$
  SELECT count(*) from crowd_source.crowd_inputs where item_id=$1.item_id;
$$ LANGUAGE SQL IMMUTABLE;


-- CREATE OR REPLACE VIEW item_count AS 
--     SELECT 
--         count(*) as total,
--         sum(case when (p.editable is false or p.completed is true) then 1 else 0 end) as finished,
--         sum(case when (p.editable is true and p.completed is false) then 1 else 0 end) as not_finished
--     FROM 
--         items p

CREATE FUNCTION child_item_count(item_id text) 
    RETURNS TABLE (
        total bigint,
        finished bigint,
        not_finished bigint
    )  
    AS $$
    BEGIN
    RETURN QUERY SELECT 
        count(*) as total,
        sum(case when (p.editable is false or p.completed is true) then 1 else 0 end) as finished,
        sum(case when (p.editable is true and p.completed is false) then 1 else 0 end) as not_finished
    FROM 
        items p
    WHERE parent_id=$1;
    END;
$$ LANGUAGE 'plpgsql';


create type strto_tsquery_t as (
    phrase text,
    plain text 
);

create function strto_tsquery(str text) returns strto_tsquery_t as $$
  select (
   replace((phraseto_tsquery($1))::text,'''',''),
   replace((plainto_tsquery($1))::text,'''','')
   )::strto_tsquery_t;
$$ LANGUAGE SQL IMMUTABLE;

-- create type item_count as (
--   total bigint,
--   finished bigint,
--   not_finished bigint
-- );


-- CREATE FUNCTION child_items(catalogs) RETURNS bigint AS $$
--   SELECT count(*) from catalogs.pages p
--   where catalog_id=$1.catalog_id
-- $$ LANGUAGE SQL IMMUTABLE;

-- CREATE FUNCTION pages_finished(catalogs) RETURNS bigint AS $$
--   SELECT count(*) from catalogs.pages p
--   where
--   catalog_id=$1.catalog_id and
--   (p.editable is false or p.completed is true)
-- $$ LANGUAGE SQL IMMUTABLE;

-- CREATE FUNCTION pages_not_finished(catalogs) RETURNS bigint AS $$
--    SELECT count(*)
--    from pages p
--    where catalog_id=$1.catalog_id and
--    (p.editable is true and p.completed is false);
-- $$ LANGUAGE SQL IMMUTABLE;