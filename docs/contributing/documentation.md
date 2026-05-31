---
title: Documentation Website
parent: Development Environment
nav_order: 3
---

# Documentation

The documentation uses [Jekyll](https://jekyllrb.com/) with the [Just the Docs](https://just-the-docs.com/) theme and is hosted
on github pages.

## Building the Documentation Locally

1. First build the documentation:

   ```console
   foo@bar:~$ cd docs
   foo@bar:~$ bundle install              # Install dependencies (only needs to be done once)
   foo@bar:~$ bundle exec jekyll serve    # Start the documentation webserver
   ```

2. Then open <http://localhost:4000> in your browser.
