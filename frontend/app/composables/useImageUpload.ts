import {
  getImageUploadPreset,
  type ImageUploadPresetId
} from '~/config/imageUpload'
import {
  convertImageForUpload,
  fileExtension,
  hasCustomImage,
  parseStoragePathFromPublicUrl,
  validateImageFile,
  type ImageFileValidationError
} from '~/utils/imageUpload'

export function useImageUpload() {
  const supabase = useSupabaseClient()

  function validate(
    file: File,
    presetId: ImageUploadPresetId
  ): ImageFileValidationError | null {
    return validateImageFile(file, presetId)
  }

  async function upload(
    presetId: ImageUploadPresetId,
    storagePath: string,
    file: File
  ): Promise<string> {
    const preset = getImageUploadPreset(presetId)
    const uploadFile = await convertImageForUpload(file, preset)
    const path = storagePath.replace(/\.[^.]+$/, '') + `.${fileExtension(uploadFile)}`

    const { error } = await supabase.storage.from(preset.bucket).upload(path, uploadFile, {
      upsert: true,
      contentType: uploadFile.type,
      cacheControl: '3600'
    })
    if (error) throw error

    const { data } = supabase.storage.from(preset.bucket).getPublicUrl(path)
    return `${data.publicUrl}?v=${Date.now()}`
  }

  async function remove(
    presetId: ImageUploadPresetId,
    options: {
      knownPublicUrl?: string | null
      candidatePaths?: string[]
      listFolder?: string
      listPrefix?: string
    }
  ): Promise<void> {
    const preset = getImageUploadPreset(presetId)
    const paths = new Set<string>()

    if (options.knownPublicUrl) {
      const fromUrl = parseStoragePathFromPublicUrl(options.knownPublicUrl, preset.bucket)
      if (fromUrl) paths.add(fromUrl)
    }

    for (const candidate of options.candidatePaths ?? []) {
      paths.add(candidate)
    }

    if (options.listFolder) {
      const { data: files, error: listError } = await supabase.storage
        .from(preset.bucket)
        .list(options.listFolder)

      if (listError) throw listError

      const prefix = options.listPrefix ?? ''
      for (const file of files ?? []) {
        if (!prefix || file.name.startsWith(prefix)) {
          paths.add(`${options.listFolder}/${file.name}`)
        }
      }
    }

    if (!paths.size) return

    const { error } = await supabase.storage
      .from(preset.bucket)
      .remove([...paths])

    if (error) throw error
  }

  return {
    validate,
    upload,
    remove,
    hasCustomImage,
    getPreset: getImageUploadPreset
  }
}
