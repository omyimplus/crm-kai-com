import { APP_SEMVER } from '~/config/appVersion'

export function useAppBuildInfo() {
  const config = useRuntimeConfig()

  const semver = computed(() => (config.public.appSemver as string) || APP_SEMVER)
  const gitCommit = computed(() => (config.public.gitCommit as string) || '')
  const gitCommitDate = computed(() => (config.public.gitCommitDate as string) || '')

  const versionLabel = computed(() => {
    const commit = gitCommit.value
    return commit ? `${semver.value} · ${commit}` : semver.value
  })

  const versionTitle = computed(() => {
    const date = gitCommitDate.value
    return date ? `Git: ${date}` : undefined
  })

  return { semver, gitCommit, gitCommitDate, versionLabel, versionTitle }
}
