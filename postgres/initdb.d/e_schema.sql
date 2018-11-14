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
    collection_id text references collections,
    parent_id text references items,
    editable boolean default true,
    completed boolean default false,
    index integer
);

CREATE TABLE crowd_inputs (
   mark_id uuid primary key,
   user_id text,
   item_id text REFERENCES items not null,
   anonymous boolean,
   data json not null,
   created timestamp without time zone,
   updated timestamp without time zone
);
create index on crowd_inputs(user_id);

CREATE FUNCTION marks(items) RETURNS bigint AS $$
  SELECT count(*) from crowd_source.crowd_inputs where item_id=$1.item_id;
$$ LANGUAGE SQL IMMUTABLE;

-- create type item_count as (
--   total bigint,
--   finished bigint,
--   not_finished bigint
-- );

-- CREATE FUNCTION child_item_count(item) RETURNS item_count AS $$
--    SELECT (
--     count(*),
--     sum(case when (p.editable is false or p.completed is true) then 1 else 0 end),
--     sum(case when (p.editable is true and p.completed is false) then 1 else 0 end)
--    )::item_count 
--    from items p
--    where parent_id=$1.item_id
-- $$ LANGUAGE SQL IMMUTABLE;


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