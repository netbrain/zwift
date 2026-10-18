---
title: Add Configuration Option
parent: Contributing
nav_order: 2
---

# Adding a Configuration Option

To add a new configuration option, follow the steps below:

1. Document what the new option does
   - `docs/configuration/options.md`
     - Add the option to the table in the list of environment variables
     - Add a section with the option's details
   - `docs/advanced/nixos.md`
     - Add the option to the example configuration
2. Add the option to the nix flake
   - `nix/module.nix`
     - Declare the option in `options.programs.zwift`
     - Add the option to `environment.systemPackages`
   - `nix/zwift-container-package.nix`
     - Add the option to the arguments list at the top
     - Add the option to the shell script builder in `nixosRun`
3. Implement the new option in `src/zwift.sh`
   - Add the option to the list of user configuration variables, also add a default value!

     ```bash
     # Initialize user configuration environment variables
     readonly VERBOSITY="${VERBOSITY:-1}"
     readonly IMAGE="${IMAGE:-docker.io/netbrain/zwift}"
     readonly VERSION="${VERSION:-latest}"
     ...
     ```

   - Add the option to the list of parameters to print

     ```bash
     parameters_to_print=(
         DEBUG VERBOSITY CONTAINER_TOOL ...
     )
     ```

   - Implement the new option
