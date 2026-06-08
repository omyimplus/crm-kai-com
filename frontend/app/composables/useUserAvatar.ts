import { DEFAULT_USER_AVATAR } from '~/config/userAvatar'
import { fileExtension } from '~/utils/imageUpload'
import { useImageUpload } from '~/composables/useImageUpload'

export function useUserAvatar() {
  const { profile } = useProfile()
  const { validate, upload, remove, hasCustomImage } = useImageUpload()

  function resolveAvatarUrl(url: string | null | undefined): string {
    return url?.trim() || DEFAULT_USER_AVATAR
  }

  function validateAvatarFile(file: File) {
    return validate(file, 'avatar')
  }

  function buildStoragePath(userId: string, file: File): string {
    const orgId = profile.value?.org_id
    if (!orgId) {
      throw new Error('Organization not found')
    }
    return `${orgId}/${userId}.${fileExtension(file)}`
  }

  async function uploadAvatar(userId: string, file: File): Promise<string> {
    await removeStoredAvatar(userId)
    const path = buildStoragePath(userId, file)
    return upload('avatar', path, file)
  }

  async function removeStoredAvatar(userId: string, knownAvatarUrl?: string | null): Promise<void> {
    const orgId = profile.value?.org_id
    if (!orgId) return

    const candidates = ['webp', 'jpg', 'jpeg', 'png', 'gif'].map(
      ext => `${orgId}/${userId}.${ext}`
    )

    await remove('avatar', {
      knownPublicUrl: knownAvatarUrl,
      candidatePaths: candidates,
      listFolder: orgId,
      listPrefix: userId
    })
  }

  return {
    resolveAvatarUrl,
    hasCustomAvatar: hasCustomImage,
    validateAvatarFile,
    uploadAvatar,
    removeStoredAvatar,
    DEFAULT_USER_AVATAR
  }
}
