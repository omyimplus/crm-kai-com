import type { ProductGalleryImage } from '~/types/crm'
import { MAX_PRODUCT_GALLERY_IMAGES } from '~/config/masterProduct'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import { useImageUpload } from '~/composables/useImageUpload'

export function useProductGallery() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()
  const { validate, upload, remove } = useImageUpload()

  function validateGalleryFile(file: File) {
    return validate(file, 'productImage')
  }

  function buildStoragePath(productId: string, imageId: string): string {
    const orgId = profile.value?.org_id
    if (!orgId) {
      throw new Error('Organization not found')
    }
    return `${orgId}/products/${productId}/gallery/${imageId}.webp`
  }

  async function list(productId: string) {
    const { data, error } = await supabase
      .from('product_gallery_images')
      .select('*')
      .eq('product_id', productId)
      .order('sort_order')
      .order('created_at')
    if (error) throw error
    return data as ProductGalleryImage[]
  }

  async function add(productId: string, file: File): Promise<ProductGalleryImage> {
    const imageId = crypto.randomUUID()
    const path = buildStoragePath(productId, imageId)
    const imageUrl = await upload('productImage', path, file)

    const { data: id, error } = await supabase.rpc('add_product_gallery_image', {
      p_product_id: productId,
      p_image_id: imageId,
      p_image_url: imageUrl
    })
    if (error) {
      await remove('productImage', {
        knownPublicUrl: imageUrl,
        candidatePaths: [path]
      }).catch(() => {})
      throw error
    }

    const rows = await list(productId)
    const row = rows.find(r => r.id === String(id))
    if (!row) {
      throw new Error('Gallery image not found after create')
    }
    return row
  }

  async function removeGalleryStorage(
    productId: string,
    imageId: string,
    knownImageUrl?: string | null
  ) {
    const orgId = profile.value?.org_id
    if (!orgId) return

    const candidates = ['webp', 'jpg', 'jpeg', 'png', 'gif'].map(
      ext => `${orgId}/products/${productId}/gallery/${imageId}.${ext}`
    )

    await remove('productImage', {
      knownPublicUrl: knownImageUrl,
      candidatePaths: candidates
    })
  }

  async function removeImage(
    productId: string,
    imageId: string,
    knownImageUrl?: string | null
  ) {
    const { data: imageUrl, error } = await supabase.rpc('remove_product_gallery_image', {
      p_image_id: imageId
    })
    if (error) throw error

    await removeGalleryStorage(
      productId,
      imageId,
      knownImageUrl ?? (typeof imageUrl === 'string' ? imageUrl : null)
    ).catch(() => {})
  }

  async function reorder(productId: string, imageIds: string[]) {
    const { error } = await supabase.rpc('reorder_product_gallery_images', {
      p_product_id: productId,
      p_image_ids: imageIds
    })
    if (error) throw error
  }

  async function removeAll(productId: string) {
    const rows = await list(productId)
    for (const row of rows) {
      await removeImage(productId, row.id, row.image_url)
    }
  }

  function galleryErrorMessage(error: unknown, t: (key: string) => string): string {
    const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
    if (message.includes('Gallery image limit reached')) {
      return t('masterData.products.gallery.validation.limitReached', {
        max: MAX_PRODUCT_GALLERY_IMAGES
      })
    }
    if (message.includes('Product not found')) {
      return t('masterData.products.gallery.validation.productNotFound')
    }
    return message || t('common.saveFailed')
  }

  return {
    maxImages: MAX_PRODUCT_GALLERY_IMAGES,
    validateGalleryFile,
    list,
    add,
    remove: removeImage,
    reorder,
    removeAll,
    galleryErrorMessage
  }
}
