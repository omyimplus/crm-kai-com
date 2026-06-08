import {
  getImageUploadPreset,
  type ImageUploadPreset,
  type ImageUploadPresetId
} from '~/config/imageUpload'

export type ImageFileValidationError = 'tooLarge' | 'invalidType'

export function validateImageFile(
  file: File,
  presetId: ImageUploadPresetId
): ImageFileValidationError | null {
  const preset = getImageUploadPreset(presetId)
  if (!preset.mimeTypes.includes(file.type)) {
    return 'invalidType'
  }
  if (file.size > preset.maxBytes) {
    return 'tooLarge'
  }
  return null
}

export function hasCustomImage(url: string | null | undefined): boolean {
  return Boolean(url?.trim())
}

export function parseStoragePathFromPublicUrl(
  publicUrl: string,
  bucket: string
): string | null {
  try {
    const pathname = new URL(publicUrl.split('?')[0]!).pathname
    const marker = `/object/public/${bucket}/`
    const idx = pathname.indexOf(marker)
    if (idx === -1) return null
    return decodeURIComponent(pathname.slice(idx + marker.length))
  } catch {
    return null
  }
}

function calcTargetSize(w: number, h: number, maxDim: number) {
  if (w <= maxDim && h <= maxDim) return { w, h }
  const ratio = Math.min(maxDim / w, maxDim / h)
  return {
    w: Math.max(1, Math.round(w * ratio)),
    h: Math.max(1, Math.round(h * ratio))
  }
}

async function fileToImage(file: File): Promise<HTMLImageElement | null> {
  if (typeof document === 'undefined' || typeof Image === 'undefined') return null

  const toDataUrl = (blob: Blob): Promise<string> =>
    new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => resolve(String(reader.result))
      reader.onerror = () => reject(new Error('Failed to read image'))
      reader.readAsDataURL(blob)
    })

  try {
    const url = await toDataUrl(file)
    const img = new Image()
    img.decoding = 'async'
    img.src = url
    await img.decode()
    return img
  } catch {
    return null
  }
}

export async function convertImageForUpload(
  file: File,
  preset: ImageUploadPreset
): Promise<File> {
  if (preset.keepSvg && file.type === 'image/svg+xml') {
    return file
  }

  const img = await fileToImage(file)
  if (!img) return file

  const srcW = img.naturalWidth || img.width
  const srcH = img.naturalHeight || img.height
  if (!srcW || !srcH) return file

  const baseName = file.name.replace(/\.[^.]+$/, '') || 'image'
  const targetType = `image/${preset.resizeFormat}`

  let lastBlob: Blob | null = null

  for (const { maxDim, quality } of preset.resizeCandidates) {
    const { w, h } = calcTargetSize(srcW, srcH, maxDim)
    const canvas = document.createElement('canvas')
    canvas.width = w
    canvas.height = h

    const ctx = canvas.getContext('2d')
    if (!ctx) return file
    ctx.clearRect(0, 0, w, h)
    ctx.drawImage(img, 0, 0, w, h)

    const blob = await new Promise<Blob | null>(resolve => {
      canvas.toBlob(b => resolve(b), targetType, quality)
    })
    if (!blob) continue

    lastBlob = blob
    if (blob.size <= preset.maxBytes) {
      return new File([blob], `${baseName}.${preset.resizeFormat}`, {
        type: targetType,
        lastModified: file.lastModified
      })
    }
  }

  if (!lastBlob) return file

  return new File([lastBlob], `${baseName}.${preset.resizeFormat}`, {
    type: targetType,
    lastModified: file.lastModified
  })
}

export function fileExtension(file: File): string {
  if (file.type === 'image/webp') return 'webp'
  if (file.type === 'image/svg+xml') return 'svg'
  if (file.type === 'image/png') return 'png'
  if (file.type === 'image/gif') return 'gif'
  return file.name.split('.').pop()?.toLowerCase() || 'jpg'
}
