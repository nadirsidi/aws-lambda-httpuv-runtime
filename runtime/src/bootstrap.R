cat("Sourcing runtime.R...\n", file = stderr())
source('/opt/runtime.R')
# TODO(nadir.sidi): Fetch additional libraries from S3 and unzip to /tmp; Add to lib path
aws.s3::save_object("plumber-3.6.3.zip", file = "/tmp/plumber-3.6.3.zip", bucket="r-plumber-lambda")
newLibPath <- "/tmp/plumber-libs/R/library"
unzip("/tmp/plumber-3.6.3.zip", exdir = "/tmp/plumber-libs")
.libPaths(c(.libPaths(), newLibPath))
cat("Successfully unzipped plumber libs and updated libPath...\n", file = stderr())
tryCatch({
    app <- initializeRuntime()
    while (TRUE) {
        handle_request(app)
        # logReset()
        # rm(list=ls())
        # source('/opt/runtime.R')
        # app <- initializeRuntime()
    }
}, error = throwInitError)
