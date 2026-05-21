---
title: Build and Test
parent: Development Environment
nav_order: 1
---

# Build and Test

## Building the Container Image

```bash
foo@bar:~$ cd src
foo@bar:~$ podman build -t zwift:dev . # Manually build the image (not recommended)
foo@bar:~$ ./build-image.sh            # It's recommended to use the build script
foo@bar:~$ ./update-image.sh           # Or only update the scripts if you already built the image
```

## Testing Changes

```console
foo@bar:~$ cd src
foo@bar:~$ DRYRUN="1" ./zwift.sh       # Print the container command instead of launching Zwift
foo@bar:~$ ZWIFT_FG="1" ./zwift.sh     # Start Zwift in the foreground to see all output
foo@bar:~$ INTERACTIVE="1" ./zwift.sh  # Open an interactive shell instead of launching Zwift
foo@bar:~$ VERBOSITY="3" ./zwift.sh    # Enable all log messages
foo@bar:~$ DEBUG="1" ./zwift.sh        # Echo all commands in the terminal
```
