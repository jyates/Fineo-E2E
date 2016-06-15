# !/bin/bash
# Run the test suite. Define environment variables here

export SCHEMA_HOME=${SCHEMA_HOME:-../schema}

bin/rspec --format doc
