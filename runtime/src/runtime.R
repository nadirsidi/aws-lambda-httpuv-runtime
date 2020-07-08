to_str <- function(x) {
    return(paste(capture.output(print(x)), collapse = "\n"))
}

error_to_payload <- function(error) {
    return(list(errorMessage = toString(error), errorType = class(error)[1]))
}

post_error <- function(error, url) {
  initializeLogging()
  logerror(error, logger = 'runtime')
  res <- POST(url,
              add_headers("Lambda-Runtime-Function-Error-Type" = "Unhandled"),
              body = error_to_payload(error),
              encode = "json")
  logdebug("Posted result:\n%s", to_str(res), logger = 'runtime')
}

get_source_file_name <- function(file_base_name) {
    file_name <- paste0(file_base_name, ".R")
    if (! file.exists(file_name)) {
        file_name <- paste0(file_base_name, ".r")
    }
    if (! file.exists(file_name)) {
        stop(paste0('Source file does not exist: ', file_base_name, '.[R|r]'))
    }
    return(file_name)
}

invoke_lambda <- function(event_response, function_name) {
    # params <- fromJSON(EVENT_DATA)
    params <- list("event_response" = event_response)
    logdebug("Invoking function '%s' with parameters:\n%s", function_name, to_str(params), logger = 'runtime')
    result <- do.call(function_name, params)
    logdebug("Function returned:\n%s", to_str(result), logger = 'runtime')
    return(result)
}

initializeLogging <- function() {
  cat("Initializing Logging...\n", file = stderr())
  library(logging)
  basicConfig()
  addHandler(writeToConsole, logger='runtime')
  log_level <- Sys.getenv('LOGLEVEL', unset = NA)
  if (!is.na(log_level)) {
      setLevel(log_level, 'runtime')
  }
}

initializeRuntime <- function() {
  cat("Initializing Runtime...\n", file = stderr())
  library(httr)
  cat("Successfully loaded httr library...\n")
  library(jsonlite)
  cat("Successfully loaded jsonlite library...\n")
  library(plumber)
  cat("Successfully loaded plumber library...\n")

  cat("Calling initializeLogging()...\n", file = stderr())
  initializeLogging()
  HANDLER <- Sys.getenv("_HANDLER")
  file_name <- get_source_file_name(HANDLER)  # Changing the handler to be the R file to plumb
  logdebug("Calling plumber::plumb on '%s'", file_name, logger = 'runtime')
  app <- plumb(file_name)

  # Return the Rook app
  return(app)
}

AWS_LAMBDA_RUNTIME_API <- Sys.getenv("AWS_LAMBDA_RUNTIME_API")
API_ENDPOINT <- paste0("http://", AWS_LAMBDA_RUNTIME_API, "/2018-06-01/runtime/")

throwInitError <- function(error) {
    url <- paste0(API_ENDPOINT, "init/error")
    post_error(error, url)
    stop()
}

throwRuntimeError <- function(error, REQUEST_ID) {
    url <- paste0(API_ENDPOINT, "invocation/", REQUEST_ID, "/error")
    post_error(error, url)
}

postResult <- function(result, REQUEST_ID) {
    url <- paste0(API_ENDPOINT, "invocation/", REQUEST_ID, "/response")
    # TODO(nadir.sidi): Change this to translate the rook named list response to a POST back to lambda API
    res <- POST(url, body = result$body, encode = "raw", content_type("text/plain; charset=UTF-8"))
    logdebug("Posted result:\n%s", str(result), logger = 'runtime')
    logdebug("Body:\n%s", result$body, logger = 'runtime')
}

handle_request <- function(app) {
    event_url <- paste0(API_ENDPOINT, "invocation/next")
    # event_response is a S3 object of type 'response'
    event_response <- GET(event_url)
    REQUEST_ID <- event_response$headers$`Lambda-Runtime-Aws-Request-Id`
    tryCatch({
      req <- build_req_env(event_response)
      resp <- httpuv:::rookCall(app$call, req, req$.bodyData, seek(req$.bodyData))
      # TODO(nadir.sidi): Invoke the correct method of the AppWrapper
      # EVENT_DATA <- rawToChar(event_response$content)
      # result <- invoke_lambda(event_response, function_name)
      # TODO(nadir.sidi) result <- AppWrapper.call(req)
      postResult(resp, REQUEST_ID)
    },
    error = function(error) {
        throwRuntimeError(error, REQUEST_ID)
    })
}

build_req_env <- function(eventResponse) {
  req <- new.env()
  logdebug("eventResponse Structure:\n", logger = 'runtime')
  # str(eventResponse)

  req$HEADERS <- c(
    "content-type" = eventResponse$headers$`content-type`
  )
  req$HTTP_ACCEPT <- eventResponse$request$headers["Accept"]
  req$HTTP_ACCEPT_ENCODING <- "gzip, deflate"
  req$HTTP_ACCEPT_LANGUAGE <- "en-US,en;q=0.5"
  req$HTTP_CONNECTION <- "keep-alive"
  req$HTTP_HOST <- "127.0.0.1/9001"
  req$HTTP_UPGRADE_INSECURE_REQUESTS <- "0"
  req$HTTP_USER_AGENT <- ""
  req$REQUEST_METHOD <- eventResponse$request$method
  req$SCRIPT_NAME <- ""
  req$PATH_INFO <- "/echo"
  req$QUERY_STRING <- "?msg=Nadir"
  req$SERVER_NAME <- "127.0.0.1"
  req$SERVER_PORT <- "9001"

  req$.bodyData <- NULL

  return(req)
}
