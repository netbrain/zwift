---
title: Test a custom Wine build
parent: Development Environment
nav_order: 2
---

# Test a custom Wine build

The custom Wine helper clones [wine-with-ble][wine-with-ble], the Wine build used to test Bluetooth Low Energy support, compiles
it inside a Debian container, and layers the resulting installation over the published Zwift image. It does not modify the
normal Zwift image.

By default the sources come from the `PR-BT-BLE` branch of `https://github.com/purm/wine-with-ble.git`, which carries the
Bluetooth Low Energy work:

```console
foo@bar:~$ cd src
foo@bar:~$ ./build-custom-wine.sh
```

Use `WINE_REPO` and `WINE_REF` to build another fork, branch, tag, or commit:

```console
foo@bar:~$ WINE_REF=my-ble-fix BASE_IMAGE=localhost/zwift:latest ./build-custom-wine.sh
```

`WINE_REPO` accepts any Git URL or local path. Only the requested revision is fetched, so a branch or tag is much cheaper than a
commit id or the full history. The image records the repository, reference, and commit it was built from in its
`org.zwift.wine.*` labels.

The out-of-tree Wine build directory is stored in a persistent container build cache. On later runs, `make` only rebuilds the
objects affected by source changes. The first build remains a complete Wine compilation.

After the build, use a separate rider name to keep the test Wine prefix apart from the normal one:

```console
foo@bar:~$ IMAGE=localhost/zwift-custom-wine VERSION=latest DONT_PULL=1 \
    DONT_CHECK=1 ZWIFT_RIDER=custom-wine-test ZWIFT_FG=1 ./zwift.sh
```

Docker users should use `IMAGE=zwift-custom-wine` instead. To discard the test prefix later, remove the `zwift-custom-wine-test`
container volume.

To force a completely clean Wine rebuild, remove the builder cache with the container tool's cache-pruning command before
running the helper again. Be aware that this also removes build caches belonging to other projects.

## Bluetooth testing

`build-ble-wine.sh` builds the same image as `localhost/zwift-custom-wine:ble-test`, and `launch-ble-wine.sh` runs it with
focused `WINEDEBUG` channels and one persistent log per run:

```console
foo@bar:~$ ./build-ble-wine.sh
foo@bar:~$ BLE_TRACE=1 ./launch-ble-wine.sh
```

Both helpers accept `WINE_REPO`, `WINE_REF`, `BASE_IMAGE`, and the `BLE_*` overrides documented in their headers. The launch
helper forces `IMAGE`, `VERSION`, `DONT_PULL`, and `DONT_CHECK`, defaults the rider to `$USER`, and writes its log to
`${XDG_STATE_HOME:-~/.local/state}/zwift-ble/zwift-ble-<wine-commit>-<timestamp>.log`.

[wine-with-ble]: https://github.com/purm/wine-with-ble
