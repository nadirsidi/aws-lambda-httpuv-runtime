## Plumber R Package Call Method

The Plumber R package implements the httpuv interface, which is a throwback to the rook webserver interface for R. This is analagous to WSGI for Python

[Comment referring to the Rook interface documentation from httpuv source code](https://github.com/rstudio/httpuv/blob/ea801f83a756eb9cd44cfc4de2182de0bf752994/R/httpuv.R#L480-L481)

## How Plumber Works

When `plumb()` is called, it creates an R6 object and parses the file with the annotations to create the proper objects for creating the API. When run is called, it simply starts an httpuv server and passes in the Plumber object as the app.

The httpuv server framework follows the rook specification, which a couple enhancements. Most importantly, the framework requires that the class used to define the app must have certain methods. It looks like the entry method is always `call(req)` and this receives an R environment.

I think the AWS runtime would have to initiate R and call plumb on the user-provided plumber-style code. Then the handler would have to call the plumber call method with the request data formatted correctly. This would then allow a plumber-style api to handle a lambda-proxy API Gateway integration.

### The `req` R Environment sent to `Plumber.call` method

From Plumber quickstart example, `ls(req)`:
```
Browse[1]> ls(req)
 [1] "HEADERS"                        "HTTP_ACCEPT"                    "HTTP_ACCEPT_ENCODING"           "HTTP_ACCEPT_LANGUAGE"          
 [5] "HTTP_CONNECTION"                "HTTP_HOST"                      "HTTP_UPGRADE_INSECURE_REQUESTS" "HTTP_USER_AGENT"               
 [9] "httpuv.version"                 "PATH_INFO"                      "QUERY_STRING"                   "REMOTE_ADDR"                   
[13] "REMOTE_PORT"                    "REQUEST_METHOD"                 "rook.errors"                    "rook.input"                    
[17] "rook.url_scheme"                "rook.version"                   "SCRIPT_NAME"                    "SERVER_NAME"                   
[21] "SERVER_PORT"                   
```

* `HEADERS`: A named character vector, the key is the names are the keys for each header
  ```
  Browse[1]> req$HEADERS
                                                                              accept
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
                                                                     accept-encoding
                                                                     "gzip, deflate"
                                                                     accept-language
                                                                    "en-US,en;q=0.5"
                                                                          connection
                                                                        "keep-alive"
                                                                                host
                                                                    "localhost:8000"
                                                           upgrade-insecure-requests
                                                                                 "1"
                                                                          user-agent
"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:77.0) Gecko/20100101 Firefox/77.0"
  ```

* `HTTP_ACCEPT`: Character string
  ```
  Browse[1]> str(req$HTTP_ACCEPT)
   chr "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
  ```

* `HTTP_ACCEPT_ENCODING`: Character string
  ```
  Browse[1]> str(req$HTTP_ACCEPT_ENCODING)
   chr "gzip, deflate"
  ```

* `HTTP_ACCEPT_LANGUAGE`: Character string
  ```
  Browse[1]> req$HTTP_ACCEPT_LANGUAGE
  [1] "en-US,en;q=0.5"
  ```

* `HTTP_CONNECTION`: Character string
  ```
  Browse[1]> req$HTTP_CONNECTION
  [1] "keep-alive"
  ```

* `HTTP_HOST`: Character string
  ```
  Browse[1]> req$HTTP_HOST
  [1] "localhost:8000"
  ```

* `HTTP_UPGRADE_INSECURE_REQUESTS`: Character string
  ```
  Browse[1]> req$HTTP_UPGRADE_INSECURE_REQUESTS
  [1] "1"
  ```

* `HTTP_USER_AGENT`: Character string
  ```
  Browse[1]> req$HTTP_USER_AGENT
  [1] "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:77.0) Gecko/20100101 Firefox/77.0"
  ```

* `httpuv.verion`: An object; Not sure if this is necessary downstream
  ```
  Browse[1]> str(req$httpuv.version)
  Classes 'package_version', 'numeric_version'  hidden list of 1
   $ : int [1:3] 1 5 2
  ```

* `PATH_INFO`: Character string of request path
  ```
  Browse[1]> req$PATH_INFO
  [1] "/echo"
  ```

* `QUERY_STRING`: Character string of query string
  ```
  Browse[1]> req$QUERY_STRING
  [1] "?msg=Nadir"
  ```

* `REMOTE_ADDR`: Character string
  ```
  Browse[1]> req$REMOTE_ADDR
  [1] "127.0.0.1"
  ```

* `REMOTE_PORT`: Character string
  ```
  Browse[1]> req$REMOTE_PORT
  [1] "50480"
  ```

* `REQUEST_METHOD`: Character string
  ```
  Browse[1]> req$REQUEST_METHOD
  [1] "GET"
  ```

* `rook.errors`: R6 class of ErrorStream; Required rook parameter; [See httpuv source](https://github.com/rstudio/httpuv/blob/ea801f83a756eb9cd44cfc4de2182de0bf752994/R/httpuv.R#L94-L169)
  ```
  Browse[1]> str(req$rook.errors)
  Classes 'ErrorStream', 'R6' <ErrorStream>
    Public:
      cat: function (..., sep = " ", fill = FALSE, labels = NULL)
      flush: function ()  
  ```

* `rook.input`: R6 class of either NullInputStream or InputStream depending on whether data is present. Required by rook framework; [See httpuv source](https://github.com/rstudio/httpuv/blob/ea801f83a756eb9cd44cfc4de2182de0bf752994/R/httpuv.R#L94-L169)
  ```
  Browse[1]> str(req$rook.input)
  Classes 'NullInputStream', 'R6' <NullInputStream>
    Public:
      close: function ()
      read: function (l = -1L)
      read_lines: function (n = -1L)
      rewind: function ()  
  ```

* `rook.url_scheme`: Character string; Required by rook (I think)
  ```
  Browse[1]> req$rook.url_scheme
  [1] "http"
  ```

* `rook.url_scheme`: Character string; Required by rook (I think)
  ```
  Browse[1]> req$rook.version
  [1] "1.1-0"
  ```

* `SCRIPT_NAME`: Character string; Not sure what this is
  ```
  Browse[1]> req$SCRIPT_NAME
  [1] ""
  ```

* `SERVER_NAME`: Character string
  ```
  Browse[1]> req$SERVER_NAME
  [1] "127.0.0.1"
  ```

* `SERVER_PORT`: Character string
  ```
  Browse[1]> req$SERVER_PORT
  [1] "8000"
  ```
