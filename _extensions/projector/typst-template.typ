#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 0.5in, y: 0.5in),
  paper: "presentation-16-9",
  lang: "en",
  region: "US",
  font: none,
  fontsize: 11pt,
  api: none,
  heading-family: none,
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: none,
  mathfont: none,
  codefont: none,
  linestretch: 1,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  handout: false,
  background: none,
  theme: none,
  doc,
) = {

  show: it => if theme != none {
    projector-theme(api, it)
  } else {
    it
  }

  set page(
    paper: paper,
    margin: margin,
    numbering: none,
    footer: context align(center)[#slide-number()],
  )

  show: it => {
    if background != none {
      set page(background: image(background, width: 100%, height: 100%))
      it
    } else {
      it
    }
  }

  set par(
    justify: false,
    leading: linestretch * 0.65em
  )

  set text(
    lang: lang,
    region: region,
    size: fontsize,
  )
  set text(font: font) if font != none
  show math.equation: set text(font: mathfont) if mathfont != none
  show raw: set text(font: codefont) if codefont != none

  show link: set text(fill: rgb(content-to-string(linkcolor))) if linkcolor != none
  show ref: set text(fill: rgb(content-to-string(citecolor))) if citecolor != none
  show link: this => {
    if filecolor != none and type(this.dest) == label {
      text(this, fill: rgb(content-to-string(filecolor)))
    } else {
      this
    }
  }

  set heading(numbering: sectionnumbering)
  show heading: set text(size: 1.5em)
  set text(size: 1.25em)

  backend-setup(handout: handout)

  let body = {
    if title != none or authors != none or date != none {
      let title-body = {
        set par(leading: heading-line-height) if heading-line-height != none
        set text(font: heading-family) if heading-family != none
        set text(weight: heading-weight) if heading-weight != none
        set text(style: heading-style) if heading-style != "normal"
        set text(fill: heading-color) if heading-color != black
        title-slide(api, title, subtitle, authors, date)
      }
      title-body
    }

    if toc {
      toc-slide(api, toc_title)
    }

    if cols == 1 {
      doc
    } else {
      columns(cols, doc)
    }
  }

  backend-apply(
    body,
    paper: paper,
    margin: margin,
    fontsize: fontsize,
    handout: handout,
    title: title,
    subtitle: subtitle,
    authors: authors,
    date: date,
    api: api,
    section-slide-fn: section-slide,
  )
}

#set table(
  inset: 6pt,
  stroke: none,
)
