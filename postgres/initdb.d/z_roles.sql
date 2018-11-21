-- the names "anon" and "authenticator" are configurable and not
-- sacred, we simply choose them for clarity
create role anon;
create role editor;
create role admin;

create role authenticator noinherit;
grant anon to authenticator;
grant editor to authenticator;
grant admin to authenticator;

grant anon to admin;
grant editor to admin;

grant usage on schema crowd_source to anon;

-- This needs to be rerun if you add tables
GRANT SELECT ON ALL TABLES IN SCHEMA crowd_source TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA crowd_source TO anon;

-- admins
GRANT INSERT on crowd_source.collections to admin;
GRANT UPDATE on crowd_source.collections to admin;
GRANT DELETE on crowd_source.collections to admin;
GRANT INSERT on crowd_source.items to admin;
GRANT UPDATE on crowd_source.items to admin;
GRANT DELETE on crowd_source.items to admin;
GRANT INSERT on crowd_source.crowd_inputs to admin;
GRANT UPDATE on crowd_source.crowd_inputs to admin;
GRANT DELETE on crowd_source.crowd_inputs to admin;
GRANT INSERT on crowd_source.suggest to admin;
GRANT UPDATE on crowd_source.suggest to admin;
GRANT DELETE on crowd_source.suggest to admin;

-- editor
GRANT INSERT on crowd_source.crowd_inputs to editor;
GRANT UPDATE on crowd_source.crowd_inputs to editor;
GRANT DELETE on crowd_source.crowd_inputs to editor;
GRANT UPDATE (editable,completed) on crowd_source.items to editor;