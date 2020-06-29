## Modifying the bakdata R Runtime

The `Dockerfile` provided by bakdata builds the R environment. The `docker build` command is wrapped by their `docker_build.sh` file.

Then, the `r/build.sh` file simply runs the default command in the built docker image and copies out all the stuff necessary for the R executable and libraries.

The `runtime/build.sh` file adds the runtime bootstrap scripts and packages that with the R exectuable. The `runtime/deploy.sh` makes the nice zip file.

To add packages to the base, runtime layer I made a new Dockerfile that takes their built docker image and then installs additional libraries. Then this new dockerfile should be the one that is run to copy out stuff in the `r/build.sh` script.

After building the second dockerfile, running `r/build.sh` and  `runtime/build.sh` the layer zip file is in `runtime/build/dist`.

## Outcome

The above approach built successfully, but the resulting layer is too big. Layers must be less than 50 MB zipped.

Second try is to build plumber in it's own layer. 
