// Match assetkit's standalone SVGO 4.1.0 optimizer.
export default {
  multipass: true,
  plugins: [
    {
      name: 'preset-default',
      params: {
        overrides: {
          minifyStyles: false,
        },
      },
    },
    'removeScripts',
  ],
}
