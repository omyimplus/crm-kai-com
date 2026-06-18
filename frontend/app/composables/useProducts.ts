import type { Product } from '~/types/crm'
import type { MasterProductFormInput } from '~/utils/masterProduct'
import { formToProductPayload } from '~/utils/masterProduct'

export function useProducts() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .is('deleted_at', null)
      .order('product_code')
    if (error) throw error
    return data as Product[]
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as Product[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Product
  }

  async function create(payload: MasterProductFormInput) {
    const { data: id, error } = await supabase.rpc('create_product', {
      p_payload: formToProductPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterProductFormInput) {
    const { error } = await supabase.rpc('update_product', {
      p_product_id: id,
      p_payload: formToProductPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function updateImage(
    id: string,
    payload: MasterProductFormInput,
    imageUrl: string | null
  ) {
    const { error } = await supabase.rpc('update_product', {
      p_product_id: id,
      p_payload: {
        ...formToProductPayload(payload),
        set_image: true,
        image_url: imageUrl
      }
    })
    if (error) throw error
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_product', {
      p_product_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_product', {
      p_product_id: id
    })
    if (error) throw error
  }

  return { list, listDeleted, get, create, update, updateImage, remove, restore }
}
