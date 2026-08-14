#let grey-gray = rgb("#dbdbdb")
#let grey-dark-gray = rgb("#4a4a4a")

#let projector-theme(api, doc) = {
  // Set the default text and background colors
  set text(fill: grey-dark-gray)
  set page(fill: grey-gray)
  show heading: it => {
    it
    v(1em)
  }
  doc
}

#let section-slide(api, name) = {
  (api.slide)[
    #text(size: 3em)[
      #name
    ]
    #(api.toolbox.register-section)(name)
  ]
}
