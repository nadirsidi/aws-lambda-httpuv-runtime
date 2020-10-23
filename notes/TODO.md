# TODO Items

* Add unit tests for runtime functions
* Figure out how to get the other plumber examples to work
* Update README
* Update license
* Clean-up all the files used for building the layer
* Package the runtime into an R package (aws.plumber)?

## Priority 1

* Build lightweight version of plumber layer that is less than 50 MB-- current built version with all dependencies is 53 MB and change.
* Forklift httpuv R6 objects into runtime.R code

## Priority 2
* Update README & license information.
* Automate building the layers in AWS CodeBuild
* Add tests
* Update serverless yaml to show example with nice Route53 url and api key

NEW APPROACH: Package Plumber and dependencies and POST them to S3; Call this archive, and unzip into /tmp at lambda runtime on coldstart. This is the Zappa slim handler approach. Path when unzipped will be `/tmp/R/library`
https://github.com/Miserlou/Zappa/blob/93804a1b3157f0189bf062e01baab2bd4f09400d/zappa/handler.py#L151-L177
