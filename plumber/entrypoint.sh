#!/bin/bash

set -euo pipefail

BUILD_DIR=/var/plumber/
R_DIR=/opt/R/

export R_LIBS=${BUILD_DIR}/R/library
mkdir -p ${R_LIBS}
${R_DIR}/bin/Rscript -e 'install.packages("plumber", repos="http://cran.r-project.org")'
