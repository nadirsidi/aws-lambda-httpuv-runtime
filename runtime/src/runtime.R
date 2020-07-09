to_str <- function(x) {
    return(paste(capture.output(print(x)), collapse = "\n"))
}

error_to_payload <- function(error) {
    return(list(errorMessage = toString(error), errorType = class(error)[1]))
}

post_error <- function(error, url) {
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

# invoke_lambda <- function(event_response, function_name) {
#     # params <- fromJSON(EVENT_DATA)
#     params <- list("event_response" = event_response)
#     logdebug("Invoking function '%s' with parameters:\n%s", function_name, to_str(params), logger = 'runtime')
#     result <- do.call(function_name, params)
#     logdebug("Function returned:\n%s", to_str(result), logger = 'runtime')
#     return(result)
# }

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

  library(httr)
  library(jsonlite)
  library(plumber)

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

postResult <- function(resp, REQUEST_ID) {
    url <- paste0(API_ENDPOINT, "invocation/", REQUEST_ID, "/response")
    # TODO(nadir.sidi): Change this to translate the rook named list response to a POST back to lambda API

    logdebug("Response from plumber:\n", logger = 'runtime')
    cat(str(resp), file = stderr())

    # API Gateway Lambda Proxy requires a very specific, JSON response format
    lambdaResponse = list(
      "statusCode" = resp$status,
      "headers" = resp$headers,
      "body" = resp$body,
      "isBase64Encoded" = FALSE
    )

    # TODO(nadir.sidi): Need to set isBase64Encoded to TRUE if binary file is returned; How to return a png image?
    res <- POST(url, body = toJSON(lambdaResponse, auto_unbox = TRUE), encode = "raw", content_type_json())

    logdebug("Response from POST result:\n")
    cat(str(res), file=stderr())
    logdebug("Response Details:\n")
    cat(str(httr::content(res)), file=stderr())
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

# Need to build tests for this 
rebuild_query_string = function(queryStringParams) {
  # Unpack the nested-list
  queryArray <- unlist(lapply(queryStringParams, function(x) unlist(x) ))
  # Rebuild the query string as-expected by plumber
  queryString <- sapply(seq(1:length(queryArray)), function(i) { paste( c(attr(queryArray, "names")[i], queryArray[i]), collapse = "=") })
  queryString <- paste0("?", queryString)
  logdebug("Query String:\t", logger='runtime')
  cat(queryString, "\n", file=stderr())
  return(queryString)
}

build_req_env <- function(eventResponse) {
  req <- new.env()

  content <- httr::content(eventResponse)

  # logdebug("Content after calling httr::content():\n", logger='runtime')
  # cat(str(content), file=stderr())

  req$HEADERS <- unlist(content$headers)
  req$HTTP_ACCEPT <- unlist(content$multiValueHeaders$Accept)
  req$HTTP_ACCEPT_ENCODING <- unlist(content$multiValueHeaders$`Accept-Encoding`)
  req$HTTP_ACCEPT_LANGUAGE <- ""
  req$HTTP_CONNECTION <- ""
  req$HTTP_HOST <- unlist(content$multiValueHeaders$Host)
  req$HTTP_UPGRADE_INSECURE_REQUESTS <- "0"
  req$HTTP_USER_AGENT <- unlist(content$multiValueHeaders$`User-Agent`)
  req$REQUEST_METHOD <- content$httpMethod
  req$SCRIPT_NAME <- ""
  req$PATH_INFO <- content$path
  req$QUERY_STRING <- rebuild_query_string(content$multiValueQueryStringParameters)
  req$SERVER_NAME <- ""
  req$SERVER_PORT <- ""

  req$.bodyData <- content$body

  return(req)
}
