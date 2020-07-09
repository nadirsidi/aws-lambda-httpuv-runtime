#!/bin/bash

set -euo pipefail

BUILD_DIR=/var/plumber/
R_DIR=/opt/R/

export R_LIBS=${BUILD_DIR}/R/library
mkdir -p ${R_LIBS}

# Make a temporary library to get helper packages that we don't want in the layer
# export R_LIBS_TMP=${BUILD_DIR}/R/tmp-library
# mkdir -p ${R_LIBS_TMP}

# ${R_DIR}/bin/Rscript -e '.libPaths(Sys.getenv("R_LIBS_TMP")); install.packages("remotes", repos = "http://cran.r-project.org")'
# ${R_DIR}/bin/Rscript -e '.libPaths(c(.libPaths(), Sys.getenv("R_LIBS_TMP"))); remotes::install_github("nadirsidi/plumber", ref = "plumber-aws")'

${R_DIR}/bin/Rscript -e 'install.packages("plumber", repos="http://cran.r-project.org")'

# rm -rf ${R_LIBS_TMP}
