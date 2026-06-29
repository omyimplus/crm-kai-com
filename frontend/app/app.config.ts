export default defineAppConfig({
  ui: {
    colors: {
      primary: 'blue',
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
