import type { Category } from '~/types/crm'
import type { MasterCategoryFormInput } from '~/utils/masterCategory'
import { CATEGORY_MODULE_KEY } from '~/config/masterCategory'
import { formToCategoryPayload } from '~/utils/masterCategory'

export function useCategories() {
  const supabase = useSupabaseClient()

  async function list(moduleKey = CATEGORY_MODULE_KEY) {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('module_key', moduleKey)
      .is('deleted_at', null)
      .order('sort_order')
      .order('category_code')
    if (error) throw error
    return data as Category[]
  }

  async function listDeleted(moduleKey = CATEGORY_MODULE_KEY) {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('module_key', moduleKey)
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as Category[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Category
  }

  async function create(payload: MasterCategoryFormInput) {
    const { data: id, error } = await supabase.rpc('create_category', {
      p_payload: formToCategoryPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterCategoryFormInput) {
    const { error } = await supabase.rpc('update_category', {
      p_category_id: id,
      p_payload: formToCategoryPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function updateImage(
    id: string,
    payload: MasterCategoryFormInput,
    imageUrl: string | null
  ) {
    const { error } = await supabase.rpc('update_category', {
      p_category_id: id,
      p_payload: {
        ...formToCategoryPayload(payload),
        set_image: true,
        image_url: imageUrl
      }
    })
    if (error) throw error
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_category', {
      p_category_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_category', {
      p_category_id: id
    })
    if (error) throw error
  }

  return { list, listDeleted, get, create, update, updateImage, remove, restore }
}
