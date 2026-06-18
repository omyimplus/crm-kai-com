import type { PipelineStage } from '~/types/crm'

/** Normalize default pipeline stage name → i18n key segment */
function pipelineStageKey(name: string | null | undefined): string {
  return (name ?? '').trim().toLowerCase().replace(/\s+/g, '_')
}

export function usePipelineStageLabel() {
  const { t, te } = useI18n()

  function pipelineStageLabel(
    stageName: string | null | undefined,
    customName?: string | null
  ): string {
    const key = pipelineStageKey(stageName ?? customName)
    const i18nKey = key ? `opportunities.stageNames.${key}` : ''

    if (key && te(i18nKey)) {
      return t(i18nKey)
    }

    const name = customName?.trim() || stageName?.trim()
    if (name) return name
    return t('opportunities.emptyCell')
  }

  function pipelineStageOptionLabel(stage: Pick<PipelineStage, 'name' | 'probability'>): string {
    return `${pipelineStageLabel(stage.name)} (${stage.probability}%)`
  }

  return { pipelineStageLabel, pipelineStageOptionLabel }
}
