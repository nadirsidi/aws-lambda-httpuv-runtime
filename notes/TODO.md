# TODO Items

Currently, plumber is failing because it can't find the function `runSteps()`. This is something I took out because it was in the async.R script, which required promises. Re-create this function, but make it sync only.

NEW APPROACH: Package Plumber and dependencies and POST them to S3; Call this archive, and unzip into /tmp at lambda runtime on coldstart. This is the Zappa slim handler approach. Path when unzipped will be `/tmp/R/library`
https://github.com/Miserlou/Zappa/blob/93804a1b3157f0189bf062e01baab2bd4f09400d/zappa/handler.py#L151-L177

## Well Fuck
Serverless Error ---------------------------------------

An error occurred: TestDashfunctionLambdaFunction - Layers consume more than the available size of 262144000 bytes (Service: AWSLambdaInternal; Status Code: 400; Error Code: InvalidParameterValueException; Request ID: a856411c-871c-4215-ad92-2968a78ccb54).

## Priority 1

* Build lightweight version of plumber layer that is less than 50 MB-- current built version with all dependencies is 53 MB and change.
* Forklift httpuv R6 objects into runtime.R code

## Priority 2
* Update README & license information.
* Automate building the layers in AWS CodeBuild
* Add tests
* Update serverless yaml to show example with nice Route53 url and api key
