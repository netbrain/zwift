---
title: Script Arguments
parent: Configuration
nav_order: 4
---

# Script Arguments

Commandline arguments for the `zwift.sh` script are forwarded to the container tool and the container entrypoint.

- Arguments that appear before `--` are forwarded to the container tool. These arguments behave the same as if they were set in
  the `CONTAINER_EXTRA_ARGS` environment variable.
- Arguments that appear after `--` are forwarded to the container entrypoint.

```console
foo@bar:~$ zwift container tool args -- container entrypoint args
```

## Examples

```bash
# the following two commands do exactly the same
zwift --cpus=1.5
CONTAINER_EXTRA_ARGS="--cpus=1.5" zwift

# update is an argument to the entrypoint script that runs inside the container
zwift -- update

# limit the number of cpu cores and pass update as argument to the entrypoint script
zwift --cpus=1.5 -- update
```

```bash
# set an environment variable and print it inside the container
INTERACTIVE=1 zwift --env HELLO="Hello, world!" -- -c 'echo "$HELLO"'

# 1. INTERACTIVE=1 enables interactive mode (-it) and sets the entrypoint to /bin/bash
# 2. --env HELLO="Hello, world!" passes the environment variable HELLO to the container
# 3. -c 'echo "$HELLO"' is passed to the /bin/bash entrypoint in the container, it executes
#    the echo "$HELLO" command inside the container, which will print "Hello, world!"
```
