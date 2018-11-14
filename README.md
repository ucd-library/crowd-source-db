# crowd-source-db
Central PostgreSQL/PostgREST (PGR) database for crowd source applications

# docker-compose

This application is comprised of a docker-compose file with 2 containers and one
volume.  Running the command `docker-compose up -d` will build the containers
and deploy the system.  You have a running API at that point.

## Dump / Restore

It often makes sense to initialize a new volume with existing data. There is a
Makefile that shows simple methods for dumping and restoring data on a running container.
