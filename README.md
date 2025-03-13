# `projector` Format

A Quarto format for making slides with [polylux](https://github.com/andreasKroepelin/polylux).
This template tries to replicate the Quarto-side syntax for [Beamer](https://quarto.org/docs/presentations/beamer.html), [PowerPoint](https://quarto.org/docs/presentations/powerpoint.html), and [Revealjs](https://quarto.org/docs/presentations/revealjs/) slides.

## Installing

```bash
quarto use template christopherkenny/projector
```

This will install the format extension and create an example `.qmd` file
that you can use as a starting place for your document.

## Using `projector` to make Polylux slides

This template includes several custom arguments that can be supplied in the YAML header.

- `handout`: If `true`, the slides will be formatted for printing as a handout. Default: `false`.


### Using other Typst functions


