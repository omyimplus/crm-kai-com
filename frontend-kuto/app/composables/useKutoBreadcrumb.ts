import { flattenKutoNav, kutoNavItems, type KutoNavNode } from '~/config/kutoMenu'

function pathMatchesNode(path: string, node: KutoNavNode): boolean {
  if (node.to === '/app') {
    return path === '/app' || path === '/app/'
  }
  return path === node.to || path.startsWith(`${node.to}/`)
}

function findDeepestNode(path: string): KutoNavNode | undefined {
  const nodes = flattenKutoNav()
  return [...nodes]
    .filter(n => pathMatchesNode(path, n))
    .sort((a, b) => b.to.length - a.to.length)[0]
}

export function useKutoBreadcrumb() {
  const route = useRoute()
  const { t } = useI18n()

  const breadcrumb = computed(() => {
    const path = route.path

    if (path === '/app' || path === '/app/') {
      return {
        module: null as string | null,
        page: t('kuto.dashboard.types.my')
      }
    }

    const pageNode = findDeepestNode(path)

    if (!pageNode) {
      return {
        module: t('kuto.nav.dashboard'),
        page: t('kuto.header.comingSoon')
      }
    }

    for (const top of kutoNavItems) {
      if (top.key === pageNode.key && !top.children?.length) {
        return { module: null as string | null, page: t(top.labelKey) }
      }
      if (pathMatchesNode(path, top)) {
        if (pageNode.key === top.key) {
          return { module: null, page: t(top.labelKey) }
        }
        return {
          module: t(top.labelKey),
          page: t(pageNode.labelKey)
        }
      }
    }

    return {
      module: t('kuto.nav.dashboard'),
      page: t(pageNode.labelKey)
    }
  })

  return { breadcrumb }
}
