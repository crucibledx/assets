const MODE = process.argv[2]
const input = await Bun.stdin.text()
const WS = {' ': '\u{F0000}', '\n': '\u{F0001}', '\t': '\u{F0002}', '\u00a0': '\u{F0003}'}
const WS_BACK = Object.fromEntries(Object.entries(WS).map(([character, placeholder]) => [placeholder, character]))

// Match assetkit's svgoKeepingWhitespace: SVGO otherwise trims HTML text nodes.
if (MODE === 'protect') {
  const collision = /[\u{F0000}-\u{F0003}]|&#(?:x0*F000[0-3]|0*98304[0-3]);/iu
  if (collision.test(input)) {
    throw new Error('SVG contains a whitespace placeholder character or character reference; refusing to optimize')
  }

  const output = input.replace(
    /(<foreignObject\b[^>]*>)([\s\S]*?)(<\/foreignObject>)/g,
    (_, open, body, close) =>
      open +
      body.replace(/>([ \n\t\u00a0]+)|([ \n\t\u00a0]+)</g, (match, afterOpen, beforeClose) =>
        afterOpen !== undefined
          ? '>' + [...afterOpen].map((character) => WS[character]).join('')
          : [...beforeClose].map((character) => WS[character]).join('') + '<',
      ) +
      close,
  )
  process.stdout.write(output)
} else if (MODE === 'restore') {
  process.stdout.write(input.replace(/[\u{F0000}-\u{F0003}]/gu, (character) => WS_BACK[character]))
} else {
  throw new Error('Usage: foreign-object-whitespace.mjs protect|restore')
}
