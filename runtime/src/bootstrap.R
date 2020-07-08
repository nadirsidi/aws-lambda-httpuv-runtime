cat("Sourcing runtime.R...\n", file = stderr())
source('/opt/runtime.R')
# TODO(nadir.sidi): Fetch additional libraries from S3 and unzip to /tmp; Add to lib path
# aws.s3::save_object("key", file = "/tmp/key.zip", bucket="bucket")
# newLibPath <- "/tmp/plumber-runtime/R/library"
# unzip(zipfile, exdir = "/tmp/plumber-runtime")
# .libPaths(c(.libPaths(), newLibPath)) 
tryCatch({
    app <- initializeRuntime()
    while (TRUE) {
        handle_request(app)
        logReset()
        rm(list=ls())
        source('/opt/runtime.R')
        app <- initializeRuntime()
    }
}, error = throwInitError)
