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

### Pass extra arguments to the container tool

```console
foo@bar:~$ zwift --cpus=1.5
foo@bar:~$ CONTAINER_EXTRA_ARGS="--cpus=1.5" zwift
```

The above two commands do exactly the same.

### Pass extra arguments to the container entrypoint

```console
foo@bar:~$ zwift -- --update
```

`--update` is an argument to the entrypoint script that runs inside the container.

### Pass extra arguments to both the container tool and the container entrypoint

```console
foo@bar:~$ zwift --cpus=1.5 -- --update
```

Limit the number of cpu cores and pass `--update` as argument to the entrypoint script.

### Set an environment variable and print it inside the container

```console
foo@bar:~$ INTERACTIVE=1 zwift --env HELLO="Hello, world!" -- -c 'echo "$HELLO"'
```

1. `INTERACTIVE=1` enables interactive mode (`-it`) and sets the entrypoint to /bin/bash
2. `--env HELLO="Hello, world!"` passes the environment variable `HELLO` to the container
3. `-c 'echo "$HELLO"'` is passed to the /bin/bash entrypoint in the container, it executes the `echo "$HELLO"` command inside
   the container, which will print `Hello, world!`
