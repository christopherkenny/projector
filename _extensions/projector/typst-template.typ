
#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1in, y: 1in),
  paper: "presentation-16-9",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  handout: false,
  background: none,
  theme: none,
  doc,
) = {

  show: it => {
    if theme != none {
      //import theme: *
      show: projector-theme
      it
    } else {
      it
    }
  }

  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )

  show: it => {
    if background != none {
      set page(background: image(background, width: 100%, height: 100%))
      it
    } else {
      it
    }
  }

  set par(justify: true)

  set text(
    lang: lang,
    region: region,
    font: font,
    size: fontsize,
  )

  set heading(numbering: sectionnumbering)
  show heading: set text(size: 1.5em)
  set text(size: 1.25em)

  if handout {
    enable-handout-mode(true)
  }

  if title != none or authors != none or date != none {
    title-slide(title, subtitle, authors, date)
  }

  if toc {
    toc-slide(toc_title)
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none,
)
