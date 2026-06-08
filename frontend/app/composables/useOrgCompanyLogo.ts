import { fileExtension } from '~/utils/imageUpload'
import { useImageUpload } from '~/composables/useImageUpload'

export function useOrgCompanyLogo() {
  const { profile } = useProfile()
  const { upload, remove } = useImageUpload()

  function buildStoragePath(profileId: string, file: File): string {
    const orgId = profile.value?.org_id
    if (!orgId) {
      throw new Error('Organization not found')
    }
    return `${orgId}/company-profiles/${profileId}.${fileExtension(file)}`
  }

  async function uploadLogo(profileId: string, file: File): Promise<string> {
    await removeLogo(profileId)
    const path = buildStoragePath(profileId, file)
    return upload('companyLogo', path, file)
  }

  async function removeLogo(profileId: string, knownLogoUrl?: string | null): Promise<void> {
    const orgId = profile.value?.org_id
    if (!orgId) return

    const folder = `${orgId}/company-profiles`
    const candidates = ['webp', 'png', 'jpg', 'jpeg', 'svg'].map(
      ext => `${folder}/${profileId}.${ext}`
    )

    await remove('companyLogo', {
      knownPublicUrl: knownLogoUrl,
      candidatePaths: candidates,
      listFolder: folder,
      listPrefix: profileId
    })
  }

  return {
    uploadLogo,
    removeLogo
  }
}
