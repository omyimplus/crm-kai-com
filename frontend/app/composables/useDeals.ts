import type { Deal, DealForm, Pipeline, PipelineStage } from '~/types/crm'

export function useDeals() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  async function list() {
    const { data, error } = await supabase
      .from('deals')
      .select('*, companies(name), contacts(first_name, last_name), pipeline_stages(name, color)')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data as Deal[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('deals')
      .select('*, companies(name), contacts(first_name, last_name), pipeline_stages(name, color)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as Deal
  }

  async function getDefaultPipeline(): Promise<{ pipeline: Pipeline, stages: PipelineStage[] }> {
    const { data: pipeline, error: pErr } = await supabase
      .from('pipelines')
      .select('*')
      .eq('is_default', true)
      .single()
    if (pErr) throw pErr

    const { data: stages, error: sErr } = await supabase
      .from('pipeline_stages')
      .select('*')
      .eq('pipeline_id', pipeline.id)
      .order('sort_order')
    if (sErr) throw sErr

    return { pipeline, stages: stages as PipelineStage[] }
  }

  async function create(payload: DealForm & { pipeline_id: string }) {
    const { data, error } = await supabase
      .from('deals')
      .insert({
        title: payload.title,
        company_id: payload.company_id,
        contact_id: payload.contact_id,
        pipeline_id: payload.pipeline_id,
        stage_id: payload.stage_id,
        amount: payload.amount,
        expected_close_date: payload.expected_close_date,
        org_id: profile.value!.org_id,
        owner_id: profile.value!.id,
        created_by: profile.value!.id
      })
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function updateStage(dealId: string, stageId: string) {
    const { data, error } = await supabase
      .from('deals')
      .update({ stage_id: stageId })
      .eq('id', dealId)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function update(id: string, payload: Partial<DealForm>) {
    const { data, error } = await supabase
      .from('deals')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function remove(id: string) {
    const { error } = await supabase
      .from('deals')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
  }

  async function stats() {
    const deals = await list()
    const open = deals.filter(d => d.status === 'open')
    const totalAmount = open.reduce((s, d) => s + Number(d.amount), 0)
    return {
      total: deals.length,
      open: open.length,
      won: deals.filter(d => d.status === 'won').length,
      totalAmount
    }
  }

  return { list, get, getDefaultPipeline, create, update, updateStage, remove, stats }
}
