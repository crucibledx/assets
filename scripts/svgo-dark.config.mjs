const WHITE = /^(?:#(?:fff|ffffff)|rgb\(\s*255\s*,\s*255\s*,\s*255\s*\)|white)$/i

function declarations(style = '') {
  const result = new Map()
  for (const declaration of style.split(';')) {
    const colon = declaration.indexOf(':')
    if (colon > 0) {
      result.set(declaration.slice(0, colon).trim(), declaration.slice(colon + 1).trim())
    }
  }
  return result
}

function withDeclarations(style, updates) {
  const result = declarations(style)
  for (const [name, value] of Object.entries(updates)) result.set(name, value)
  return [...result].map(([name, value]) => `${name}:${value}`).join(';')
}

function isBackgroundRect(element) {
  return (
    element?.type === 'element' &&
    element.name === 'rect' &&
    element.attributes.width === '100%' &&
    element.attributes.height === '100%' &&
    WHITE.test(element.attributes.fill?.trim() ?? '')
  )
}

// Dark generation is an AST transform, not a text substitution: only assetkit's
// root insertion point may change, even when nested artwork has identical attrs.
export default {
  multipass: false,
  plugins: [
    {
      name: 'crucibleDarkTheme',
      fn: () => ({
        element: {
          enter(node, parent) {
            if (node.name !== 'svg' || parent.type !== 'root') return

            node.attributes.style = withDeclarations(node.attributes.style, {
              background: 'transparent',
              'background-color': 'transparent',
              'color-scheme': 'dark',
              filter: 'invert(1) hue-rotate(180deg)',
            })

            const defsIndex = node.children.findIndex((child) => child.type === 'element' && child.name === 'defs')
            const background =
              defsIndex >= 0
                ? node.children.find((child, index) => index > defsIndex && child.type === 'element')
                : node.children.find((child) => child.type === 'element')
            if (!isBackgroundRect(background)) return

            const inlineFill = declarations(background.attributes.style).get('fill')
            if (inlineFill && !WHITE.test(inlineFill)) return

            background.attributes.fill = 'transparent'
            if (inlineFill) {
              background.attributes.style = withDeclarations(background.attributes.style, {fill: 'transparent'})
            }
          },
        },
      }),
    },
  ],
}
