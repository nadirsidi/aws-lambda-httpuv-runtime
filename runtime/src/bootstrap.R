source('/opt/runtime.R')
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
