#!/usr/bin/env bash
# Run the test suite. Define environment variables here

export SCHEMA_HOME=${SCHEMA_HOME:-../schema/schema-lambda-e2e/target}

bin/rspec --format doc
