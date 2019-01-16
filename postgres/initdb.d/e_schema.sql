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
    collection_id text primary key, -- URI
    name text,
    description text
);

CREATE TABLE applications (
    app_id text primary key,
    name text,
    description text
);

CREATE TABLE items (
    item_id text primary key, -- URI
    app_id text references applications not null,
    collection_id text references collections not null, -- URI
    parent_item_id text references items, -- URI
    root_item_id text references items, -- URI
    CONSTRAINT unq_app_item UNIQUE(item_id, app_id)
);
create index on items(app_id);
create index on items(collection_id);
create index on items(parent_item_id);
create index on items(root_item_id);

CREATE TABLE app_item_metadata (
    app_item_metadata_id uuid primary key default public.gen_random_uuid(),
    app_id text references applications not null,
    item_id text references items not null, -- URI
    editable boolean default true,
    completed boolean default false,
    index integer,
    extra json,
    CONSTRAINT unq_app_item UNIQUE(item_id, app_id)
);
create index on items(app_id);
create index on items(item_id);
create index on items(index);

CREATE TABLE crowd_inputs (
   crowd_input_id text primary key,
   app_id text references applications not null,
   item_id text REFERENCES items not null, -- URI
   user_id text,
   schema_id text not null, 
   anonymous boolean,
   data json not null,
   created timestamp without time zone,
   updated timestamp without time zone
);
create index on crowd_inputs(app_id);
create index on crowd_inputs(item_id);
create index on crowd_inputs(user_id);
create index on crowd_inputs(schema_id);

CREATE TABLE suggest (
   suggest_id uuid primary key default public.gen_random_uuid(),
   collection_id text REFERENCES collections not null, -- URI
   app_id text references applications not null,
   name text not null,
   text text not null,
   tsv tsvector
);
create index on suggest(name);
create unique index idx_suggest_unique on suggest(app_id, collection_id, domain, text);

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


CREATE FUNCTION find_root_item_id_trig() RETURNS trigger as $find_root_item_id_trig$
    BEGIN
        IF NEW.parent_item_id is not null THEN
            NEW.root_item_Id := select find_root_item_id(NEW.parent_item_id);
        END IF;
        RETURN NEW;
    END
$gen_app_item_id$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION find_root_item_id (
    parent_id text ) RETURNS text as $$
DECLARE
    iid text;
    pid text;
BEGIN
    select item_id into iid, parent_item_id into pid from items where parent_item_id = parent_id;
    
    IF( pid IS NOT NULL ) THEN
        return SELECT find_root_item_id(pid)
    END IF;

    RETURN iid;
END;
$$ LANGUAGE plpgsql 


CREATE TRIGGER find_root_item_id_trig BEFORE INSERT OR UPDATE ON items
    FOR EACH ROW EXECUTE PROCEDURE find_root_item_id_trig();


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

-- TODO: have to proxy handle this
create function strto_tsquery(str text) returns strto_tsquery_t as $$
  select (
   replace((phraseto_tsquery($1))::text,'''',''),
   replace((plainto_tsquery($1))::text,'''','')
   )::strto_tsquery_t;
$$ LANGUAGE SQL IMMUTABLE;