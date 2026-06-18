import { fileExtension } from '~/utils/imageUpload'
import { useImageUpload } from '~/composables/useImageUpload'

export function useProductImage() {
  const { profile } = useProfile()
  const { validate, upload, remove } = useImageUpload()

  function validateProductImageFile(file: File) {
    return validate(file, 'productImage')
  }

  function buildStoragePath(productId: string, file: File): string {
    const orgId = profile.value?.org_id
    if (!orgId) {
      throw new Error('Organization not found')
    }
    return `${orgId}/products/${productId}.${fileExtension(file)}`
  }

  async function uploadProductImage(productId: string, file: File): Promise<string> {
    await removeProductImage(productId)
    const path = buildStoragePath(productId, file)
    return upload('productImage', path, file)
  }

  async function removeProductImage(
    productId: string,
    knownImageUrl?: string | null
  ): Promise<void> {
    const orgId = profile.value?.org_id
    if (!orgId) return

    const folder = `${orgId}/products`
    const candidates = ['webp', 'jpg', 'jpeg', 'png', 'gif'].map(
      ext => `${folder}/${productId}.${ext}`
    )

    await remove('productImage', {
      knownPublicUrl: knownImageUrl,
      candidatePaths: candidates,
      listFolder: folder,
      listPrefix: productId
    })
  }

  return {
    validateProductImageFile,
    uploadProductImage,
    removeProductImage
  }
}
