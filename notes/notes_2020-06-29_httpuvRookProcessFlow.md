
## Local Operation of **httpuv** and **plumber**

1. User calls Plumber object, `run()` method to start a local server. This does a bunch of Swagger stuff and plays with the file paths to make it look like the server is running in the local working dir. Ultimately, [it's a wrapper for `httpuv::runServer`](https://github.com/rstudio/plumber/blob/43067ff5849388daaf1d62c5b9f2418ba272a70c/R/plumber.R#L376).

2. `httpuv::runServer` which calls `httpuv::startServer`. At this point, the app (Plumber object) is being passed through

3. `httpuv::startServer` creates a new `WebServer` R6 object

4. The `WebServer` object binds the underlying C web service to the app methods it should call. [See definition here.](https://github.com/rstudio/httpuv/blob/ea801f83a756eb9cd44cfc4de2182de0bf752994/R/server.R#L160-L200). All the `AppWrapper` class stuff is just an implementation of the rook interface, which Plumber apps respect.

5. For a simple GET request, such as the `/echo` path example from the R Plumber quickstart, the `AppWraper$call(req, cpp_callback)` method is invoked by the `WebServer` instance. The `cpp_callback` is the C web server callback to return the response. Otherwise, the `req` is an R environment that has all the rook info.

6. Then the `AppWrapper` does some pre-processing to make the necessary rook inputs and then passes the call to the `Plumber.call(req)` method. The callback pointer is dropped.

7. The `Plumber.call(req)` method creates a new instance of the `PlumberResponse` R6 object with the necessary response serializer

8. Then the `Plumber.serve(req, res)` method is called. This does all the fancy routing and processing.

9. Following the rook interface, Plumber ultimately gives back a response in the form of a list.
  ```
  Browse[1]> str(resp)
  List of 3
   $ status : int 200
   $ headers:List of 1
    ..$ Content-Type: chr "application/json"
   $ body   : 'json' chr "{\"msg\":[\"The message is: 'message'\"]}"
  ```  

10. Finally, `AppWrapper` finishes the `call` method by invoking the C web server callback with the response list.


## MVP Steps to Replace **httpuv** with AWS Lambda proxy

### Lambda Initialization (see function `initializeRuntime`)
1. Bootstrap runtime starting with shell script from bakdata to start `Rscript` executable with `bootstrap.R`
2. Load libraries, including plumber
3. Wrap the plumber code in a lightweight version of AppWrapper.

### Updates to bakdata `runtime.R` functions:

* `get_source_file_name()` should be repurposed to get the plumber app file name.
* `initializeRuntime` should load plumber library, plumb the file, and create a new AppWrapper
* `invoke_lambda` should pass the request to or be replaced by `AppWrapper.call()`
* `handle_request` should be updated, see below.
* `throwRuntimeError` should be the rook.errors `ErrorStream` cat method.

### New `handle_request` Rook implementation

1. (existing functionality) Get the event information from the internal Lambda API
2. Instead of getting out the data, translate the entire Lambda Proxy event to the necessary `req` R environment.
3. Pass the newly-created R environment to the applicable `AppWrapper` method via `invoke_lambda`. Include `REQUEST_ID`.
4. `AppWrapper` method should then call `postResult` to translate the rook response list and post with the `REQUEST_ID`.
