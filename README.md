
# `projector` Format <img src='projector.png' align="right" height="150" />

A Quarto format for making slides with [polylux](https://github.com/andreasKroepelin/polylux).
This template tries to replicate the Quarto-side syntax for [Beamer](https://quarto.org/docs/presentations/beamer.html), [PowerPoint](https://quarto.org/docs/presentations/powerpoint.html), and [Revealjs](https://quarto.org/docs/presentations/revealjs/) slides.

<!-- pdftools::pdf_convert('template.pdf') -->
![[template.qmd](template.qmd)](example.gif)

## Design principles

In order of importance:

1. Replicate the syntax of existing Quarto beamer slides so that `projector` can be used as a drop-in extension for the beamer type, up to any additional LaTeX-specific styling.

2. Incorporate `polylux` features automatically, so that functions like `#slide` or `#toolbox.register-section` never need to be modified directly, but are fully controlled by regular Quarto features.

3. Minimize nonstandard defaults. By setting as few features up automatically as possible, this should be customizeable using a header `.typ` file. When an option would be hard to control otherwise, it should be controlled via a YAML option in the Quarto doc.

## Installing

```bash
quarto use template christopherkenny/projector
```

This will install the format extension and create an example `.qmd` file
that you can use as a starting place for your slides.

## Using `projector` to make Polylux slides

This template includes several custom arguments that can be supplied in the YAML header.

- `mainfont`: sets font (see options with `quarto typst fonts`)
- `margin`: sets page margins
- `papersize`: the paper size to use (choices listed [here](https://typst.app/docs/reference/layout/page/))
- `toc`: whether to display the table of contents
- `toc_title`: title of the table of contents
- `background-image`: the path to an image to put as the background
- `handout`: display as a handout, removing incrementals
- `theme`: a file name containing your customizations

## Controlling Title, ToC, and Sections Slides

To modify these three particular slides, you need to adjust them in your template file.
Simply redefine the functions that produce them with your own version.

The function signatures should be as follows:

- `title-slide(title, subtitle, authors, date)`
- `toc-slide(toc_title)`
- `section-slide(name)`

### Using other Typst functions

This extension comes preloaded with my [`typst-function`](https://github.com/christopherkenny/typst-function) Quarto extension to make it easy to use bits of Typst for formatting.
This feature is entirely optional, but may simplify making tweaks to your slides.

Divs and spans that match names listed in the `functions` key are translated to Typst functions of the same name.
Adding this to your metadata:

```yaml
functions: align
```

Allows you to write:

```md
::: {.align arguments="right"}
this
:::
```

Spans function similarly, so you can style like:

```md
[other text]{.align arguments=right}
```


## License

This template is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Thoughts from the author

I actually quite dislike beamer and similar slide styles that are automatically generated.
I find that they are (1) typically ugly and (2) encourage bad presenting habits.
If it's too easy to go from the paper to the presentation, people rarely think through the presentation.
My view is that presentations and papers have different goals.
A paper needs to convey all of the scientific components that support why your work advances knowledge.
A presentation is more of an infomercial for the paper.
That means you can tell the story of the paper.
It should be truthful and scientific, but it should also be interesting.
Tell the practical pieces, tell the hiccups along the way, make it clear how you came up with the project.
Finally, it's okay if it looks nice: don't be worried that an aesthetically pleasing presentation implies you spent a little time on form instead of just function.
Hopefully, this extension helps bridge the gap between form and function, by using the prettier `polylux` with the simplicity of `beamer` via Quarto.

The logo for this *project* (haha) is inspired by `polylux`'s logo.
The name is also inspired by`polylux`'s name origin story, where to me, an updated "beamer" is a "projector".
