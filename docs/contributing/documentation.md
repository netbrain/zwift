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

## Theme

The site uses Just the Docs with a Zwift-inspired look. The customizations live in these files:

| File                                  | Purpose                                                                         |
|:--------------------------------------|:--------------------------------------------------------------------------------|
| `_sass/color_schemes/light.scss`      | Light color scheme, also the base for the dark scheme                           |
| `_sass/color_schemes/dark.scss`       | Dark color scheme                                                               |
| `_sass/custom/setup.scss`             | Font stacks                                                                     |
| `_sass/custom/custom.scss`            | Styling for headings, navigation zones, callouts and the custom components      |
| `_includes/head.html`                 | Copy of the theme file that loads both color schemes, see note below            |
| `_includes/js/custom.js`              | Theme toggle, route profile, segments list and previous/next links              |
| `_includes/title.html`                | Logo and site title                                                             |
| `_includes/header_custom.html`        | Theme toggle button                                                             |
| `_includes/footer_custom.html`        | Previous/next links and the Ride On box                                         |
| `assets/fonts/`                       | Self-hosted Barlow and JetBrains Mono (latin subset) with their OFL licenses    |

The site follows the system light/dark preference. The theme toggle in the header overrides it, and the choice is stored in
the browser.

Navigation sections are tagged like power zones (Z1 to Z5) to show how demanding they are. The mapping from section to zone is
the `$zw-zones` map in `_sass/custom/custom.scss`.

{: .important }
`_includes/head.html` is a copy of the Just the Docs 0.12.0 file with one block changed. When upgrading Just the Docs,
copy the new upstream file and apply the change again.
