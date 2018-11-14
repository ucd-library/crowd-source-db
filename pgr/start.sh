#!/bin/bash

export PGT_ANON=${PGT_ANON:-anon}
export PGT_JWT=${PGT_JWT:-bad_secret}

# Wait for PG to come-online
wait-for-it -t 5 postgres:5432 -- echo 'postgres is hot'

# Initialize postgrest
envsubst < /etc/pgt_envsubst.conf > /etc/postgrest.conf
postgrest /etc/postgrest.conf 