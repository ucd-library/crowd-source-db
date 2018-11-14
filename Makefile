#! /usr/bin/make

dc:=docker-compose
db:=postgres
pg:=${dc} exec --user postgres postgres
date:=$(shell date --iso)
dump-items.Fc:=/app/Fc/items_${date}.Fc
dump-crowd-inputs.Fc:=/app/Fc/crowd_inputs_${date}.Fc

dump-items:
	${pg} pg_dump -Fc --file=${dump-items.Fc} -a \
  --table=crowd_source.collections --table=crowd_source.items ${db}

dump-crowd-inputs:
	${pg} pg_dump -Fc --file=${dump-crowd-inputs.Fc} -a  --table=crowd_source.crowd_inputs ${db}

restore-items:
	${pg} pg_restore --dbname=${db} ${dump-items.Fc}

restore-crowd-inputs:
	${pg} pg_restore --dbname=${db} ${dump-crowd-inputs.Fc}
