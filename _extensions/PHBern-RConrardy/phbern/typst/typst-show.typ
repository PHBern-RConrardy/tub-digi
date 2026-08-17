#show <refs>: refs => {
  block(above: 6pt)[#refs]
}

#show: doc => phbern(
$if(title)$
  title: "$title$",
$endif$
$if(subtitle)$
  subtitle: "$subtitle$",
$endif$
$if(author)$
  author: "$author$",
$endif$
$if(institut)$
  institut: "$institut$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-title)$
  toc-title: [$toc-title$],
$endif$
$if(toc-indent)$
  toc-indent: $toc-indent$,
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$else$
  toc-depth: 3,
$endif$
  body: doc,
)
