---
title: Authentication
parent: Configuration
nav_order: 2
---

# Authentication

## How can I persist my login information so i don't need to login on every startup?

One way to authenticate through Zwift automatically, is to add the username and password to `$HOME/.config/zwift/config`:

```bash
ZWIFT_USERNAME='username'
ZWIFT_PASSWORD='password'
```

Where `username` is your zwift account email, and `password` your zwift account password, respectively.

This however has the disadvantage that your password is written in plain text in the config file. Alternatively, instead of
saving your password in the config file, you can store it securely in the secret service keyring like so:

```bash
secret-tool store --label "Zwift password for ${ZWIFT_USERNAME}" application zwift username ${ZWIFT_USERNAME}
```

In this case the username should still be saved in the config file.

{: .note }
It is recommended to save your password securely in the secret store and add your username to the config file.
