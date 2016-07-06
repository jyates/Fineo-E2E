#!/usr/bin/env bash
# Run the test suite. Define environment variables here.

# Setting debug to anything will turn on debug output
#export DEBUG=1

export SCHEMA_HOME=${SCHEMA_HOME:-../schema/schema-lambda-e2e/target}
export INGEST_WRITE_HOME=${INGEST_WRITE_HOME:-../ingest/pipeline/stream-processing-e2e/target}
export BATCH_ETL_HOME=${BATCH_ETL_HOME:-../ingest/batch-parent/batch-etl-e2e/target}

bin/rspec --format doc
