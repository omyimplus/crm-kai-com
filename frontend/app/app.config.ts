export default defineAppConfig({
  ui: {
    colors: {
      primary: 'green',
      neutral: 'slate'
    },
    modal: {
      variants: {
        overlay: {
          true: {
            overlay: 'bg-black/60'
          }
        }
      }
    }
  }
})
