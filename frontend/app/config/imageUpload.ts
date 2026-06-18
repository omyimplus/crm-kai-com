/** Presets สำหรับอัปโหลดรูปทั้งระบบ — ดู docs/05-frontend/IMAGE-UPLOAD.md */

export type ImageUploadPresetId = 'avatar' | 'companyLogo' | 'categoryImage' | 'productImage'

export interface ImageResizeCandidate {
  maxDim: number
  quality: number
}

export interface ImageUploadPreset {
  id: ImageUploadPresetId
  bucket: string
  maxBytes: number
  accept: string
  mimeTypes: string[]
  resizeFormat: 'webp'
  resizeCandidates: ImageResizeCandidate[]
  /** ไม่แปลง SVG เป็น webp (เช่น company logo) */
  keepSvg: boolean
}

export const IMAGE_UPLOAD_PRESETS: Record<ImageUploadPresetId, ImageUploadPreset> = {
  avatar: {
    id: 'avatar',
    bucket: 'avatars',
    maxBytes: 5 * 1024 * 1024,
    accept: 'image/jpeg,image/png,image/webp,image/gif',
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    resizeFormat: 'webp',
    resizeCandidates: [
      { maxDim: 512, quality: 0.85 },
      { maxDim: 384, quality: 0.8 },
      { maxDim: 256, quality: 0.72 },
      { maxDim: 192, quality: 0.65 },
      { maxDim: 128, quality: 0.55 }
    ],
    keepSvg: false
  },
  companyLogo: {
    id: 'companyLogo',
    bucket: 'org-images',
    maxBytes: 2 * 1024 * 1024,
    accept: 'image/jpeg,image/png,image/webp,image/svg+xml',
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml'],
    resizeFormat: 'webp',
    resizeCandidates: [
      { maxDim: 800, quality: 0.88 },
      { maxDim: 640, quality: 0.82 },
      { maxDim: 480, quality: 0.75 },
      { maxDim: 320, quality: 0.68 }
    ],
    keepSvg: true
  },
  categoryImage: {
    id: 'categoryImage',
    bucket: 'org-images',
    maxBytes: 2 * 1024 * 1024,
    accept: 'image/jpeg,image/png,image/webp,image/gif',
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    resizeFormat: 'webp',
    resizeCandidates: [
      { maxDim: 640, quality: 0.85 },
      { maxDim: 480, quality: 0.8 },
      { maxDim: 320, quality: 0.72 },
      { maxDim: 240, quality: 0.65 }
    ],
    keepSvg: false
  },
  productImage: {
    id: 'productImage',
    bucket: 'org-images',
    maxBytes: 2 * 1024 * 1024,
    accept: 'image/jpeg,image/png,image/webp,image/gif',
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    resizeFormat: 'webp',
    resizeCandidates: [
      { maxDim: 800, quality: 0.85 },
      { maxDim: 640, quality: 0.8 },
      { maxDim: 480, quality: 0.72 },
      { maxDim: 320, quality: 0.65 }
    ],
    keepSvg: false
  }
}

export function getImageUploadPreset(id: ImageUploadPresetId): ImageUploadPreset {
  return IMAGE_UPLOAD_PRESETS[id]
}
