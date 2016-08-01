#!/usr/bin/env bash
# Run the test suite. Define environment variables here.

# Setting debug to anything will turn on debug output
#export DEBUG=1

export SCHEMA_HOME=${SCHEMA_HOME:-../schema/schema-lambda-e2e}
export INGEST_WRITE_HOME=${INGEST_WRITE_HOME:-../ingest/pipeline/stream-processing-e2e}
export BATCH_ETL_HOME=${BATCH_ETL_HOME:-../ingest/batch-parent/batch-etl-e2e}
export DRILL_READ_HOME=${DRILL_READ_HOME:-../readerator/e2e-testing}

bin/rspec --format doc
