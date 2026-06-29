const open = ref(false)

export function useKutoMobileNav() {
  return {
    open: readonly(open),
    toggle: () => { open.value = !open.value },
    close: () => { open.value = false }
  }
}
