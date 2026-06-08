import { execSync } from 'node:child_process'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), '../..')

function runGit(command) {
  return execSync(command, { cwd: repoRoot, encoding: 'utf8' }).trim()
}

/** @returns {{ commit: string, commitDate: string }} */
export function getGitBuildInfo() {
  const commitFromEnv = process.env.NUXT_PUBLIC_GIT_COMMIT?.trim()
  if (commitFromEnv) {
    return {
      commit: commitFromEnv,
      commitDate: process.env.NUXT_PUBLIC_GIT_COMMIT_DATE?.trim() || ''
    }
  }

  try {
    return {
      commit: runGit('git rev-parse --short HEAD'),
      commitDate: runGit('git log -1 --format=%cI')
    }
  }
  catch {
    return { commit: '', commitDate: '' }
  }
}
