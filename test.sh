#!/usr/bin/env bash
# Run the test suite. Define environment variables here.

# Setting debug to anything will turn on debug output
#export DEBUG=1

current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export EXT_HOME=${EXT_HOME:-ext}
export SCHEMA_HOME=${SCHEMA_HOME:-${current}/../schema/schema-lambda-e2e}
export INGEST_WRITE_HOME=${INGEST_WRITE_HOME:-${current}/../ingest/pipeline/stream-processing-e2e}
export BATCH_ETL_HOME=${BATCH_ETL_HOME:-${current}/../ingest/batch-etl-parent/batch-etl-e2e}
export DRILL_STANDALONE_HOME=${DRILL_STANDALONE_HOME:-${current}/../readerator/drill-standalone}
export DRILL_LOCAL_READ_HOME=${DRILL_LOCAL_READ_HOME:-${current}/../readerator/e2e/e2e-testing}
export SERVER_HOME=${SERVER_HOME:-${current}/../readerator/readerator/server}
export DRILL_REMOTE_READ_HOME=${DRILL_REMOTE_READ_HOME:-${current}/../readerator/e2e/e2e-read-testing}

# You can also just pass through arguments to rspec. In particular, its likely the "--tag" 
# option will be helpful. For instance, to just run the  local tests you would do:
# ./test.sh --tag mode:local

# Optionally, you could also specify:  "--pattern <full path to current dir>/standalone/*.rbstandalone/*" to run a standalone instance
cd ${current}
${current}/bin/rspec --format doc ${current} $@
