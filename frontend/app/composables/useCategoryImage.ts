import { fileExtension } from '~/utils/imageUpload'
import { useImageUpload } from '~/composables/useImageUpload'

export function useCategoryImage() {
  const { profile } = useProfile()
  const { validate, upload, remove } = useImageUpload()

  function validateCategoryImageFile(file: File) {
    return validate(file, 'categoryImage')
  }

  function buildStoragePath(categoryId: string, file: File): string {
    const orgId = profile.value?.org_id
    if (!orgId) {
      throw new Error('Organization not found')
    }
    return `${orgId}/categories/${categoryId}.${fileExtension(file)}`
  }

  async function uploadCategoryImage(categoryId: string, file: File): Promise<string> {
    await removeCategoryImage(categoryId)
    const path = buildStoragePath(categoryId, file)
    return upload('categoryImage', path, file)
  }

  async function removeCategoryImage(
    categoryId: string,
    knownImageUrl?: string | null
  ): Promise<void> {
    const orgId = profile.value?.org_id
    if (!orgId) return

    const folder = `${orgId}/categories`
    const candidates = ['webp', 'jpg', 'jpeg', 'png', 'gif'].map(
      ext => `${folder}/${categoryId}.${ext}`
    )

    await remove('categoryImage', {
      knownPublicUrl: knownImageUrl,
      candidatePaths: candidates,
      listFolder: folder,
      listPrefix: categoryId
    })
  }

  return {
    validateCategoryImageFile,
    uploadCategoryImage,
    removeCategoryImage
  }
}
