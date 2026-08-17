#let phbern(
  title: none,
  subtitle: none,
  author: none,
  institut: "Sekundarstufe II",
  toc: false,
  toc-title: none,
  toc-depth: 3,
  toc-indent: 1.5em,
  body: none,
) = {
  set text(font: "Liberation Sans", size: 10.5pt, lang: "de")
  set par(leading: 0.58em)

  set page(
    paper: "a4",
    margin: (left: 23mm, right: 23mm, top: 25mm, bottom: 24mm),
    header-ascent: 0pt,
    footer-descent: 0%,
    footer: none,

    header: [
  #block(width: 100%, height: 12mm)[

    #place(top + left)[
      #set text(font: "Liberation Sans", size: 8pt)

      #stack(
        dir: ttb,
        spacing: 2.5pt,
        [#text(weight: "bold")[Institut #institut]],
        [Fabrikstrasse 8, CH-3012 Bern],
        [#str("T +41 31 309 21 15, contactdesk@phbern.ch, www.phbern.ch")],
      )
    ]

    #place(top + right, dy: -10pt)[
      #image("$logo.path$", width: 70mm)
    ]

    #place(bottom + left)[
      #rect(width: 100%, height: 2pt, fill: black, stroke: none)
      #v(8pt)
    ]
  ]
],
  )

  show link: set text(fill: rgb("#ad0101"))
  show strong: set text(weight: "bold")
  set table(
    stroke: 0.45pt + rgb("#8f8f8f"),
    fill: (_, y) => if y == 0 { rgb("#f3f3f3") },
  )
  show table.cell.where(y: 0): it => {
    table.cell[
      #set text(weight: "bold")
      #it
    ]
  }

// Title block: title, subtitle, author all flush left.
if title != none or subtitle != none or author != none {
  block(width: 100%, inset: (top: 12pt), below: 12pt)[
    #set align(left)
    #set text(font: "Liberation Sans")

    #stack(
      dir: ttb,
      spacing: 7pt,

      if title != none {
        text(size: 14pt, weight: "bold")[#title]
      },

      if subtitle != none {
        text(size: 14pt)[#subtitle]
      },

      if author != none {
        block(above: 12pt)[
          #text(size: 10pt)[#author]
        ]
      },
    )
  ]
}

if toc {
  let outline-title = if toc-title == none {
    auto
  } else {
    toc-title
  }

  block(above: 2pt, below: 18pt)[
    #outline(
      title: outline-title,
      depth: toc-depth,
      indent: toc-indent,
    )
  ]
}

  // Numbered headings:
  // 1      Heading 1
  // 1.1    Heading 2
  // 1.1.1  Heading 3 and deeper levels
  set heading(numbering: "1.1")

  let numbered-heading(size: 10pt, above: 10pt, below: 6pt, number-width: 17mm) = it => {
    if it.numbering == none {
      block(above: above, below: below, width: 100%)[
        #set text(size: size, weight: "bold")
        #it.body
      ]
      return
    }

    context {
      let nums = counter(heading).at(it.location())
      let num = numbering("1.1", ..nums)

      block(above: above, below: below, width: 100%)[
        #set text(size: size, weight: "bold")

        #grid(
          columns: (number-width, 1fr),
          gutter: 0pt,
          align: (left, left),
          [#num],
          [#it.body],
        )
      ]
    }
  }

  show heading.where(level: 1): numbered-heading(
    size: 11pt,
    above: 18pt,
    below: 10pt,
    number-width: 17mm,
  )

  show heading.where(level: 2): numbered-heading(
    size: 10pt,
    above: 15pt,
    below: 8pt,
    number-width: 17mm,
  )

  show heading.where(level: 3): numbered-heading(
    size: 10pt,
    above: 12pt,
    below: 7pt,
    number-width: 17mm,
  )

  show heading.where(level: 4): numbered-heading(
    size: 10pt,
    above: 10pt,
    below: 6pt,
    number-width: 17mm,
  )

  show heading.where(level: 5): numbered-heading(
    size: 10pt,
    above: 8pt,
    below: 5pt,
    number-width: 17mm,
  )

  body


}
