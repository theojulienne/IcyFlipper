#!/bin/sh
script_file="build_dsss.sh"

echo "Running DSSS build phase ($script_file)"
${PROJECT_DIR}/scripts/${script_file}
scriptExitStatus=$?
exit "${scriptExitStatus}"
