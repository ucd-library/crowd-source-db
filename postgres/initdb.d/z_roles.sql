-- the names "anon" and "authenticator" are configurable and not
-- sacred, we simply choose them for clarity
create role anon;
create role markup;
create role admin;

create role authenticator noinherit;
grant anon to authenticator;
grant markup to authenticator;
grant admin to authenticator;

grant anon to admin;
grant markup to admin;

grant usage on schema crowd_source to anon;

-- This needs to be rerun if you add tables
GRANT SELECT ON ALL TABLES IN SCHEMA crowd_source TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA crowd_source TO anon;

-- Admin can't delete pages, etc.
GRANT INSERT on crowd_source.crowd_inputs to markup;
GRANT UPDATE on crowd_source.crowd_inputs to markup;
GRANT DELETE on crowd_source.crowd_inputs to markup;

GRANT UPDATE (editable,completed) on crowd_source.items to markup;