<script setup lang="ts">
import type { PipelineStage } from '~/types/crm'
import {
  appFormErrorClass,
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi
} from '~/config/appFormUi'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  stages: PipelineStage[]
}>()

const emit = defineEmits<{ saved: [] }>()

const { t } = useI18n()
const { create, getDefaultPipeline } = useDeals()
const { list: listCompanies } = useCompanies()
const { list: listContacts } = useContacts()

const loading = ref(false)
const errorMsg = ref('')

const form = reactive({
  title: '',
  company_id: null as string | null,
  contact_id: null as string | null,
  stage_id: '',
  amount: 0,
  expected_close_date: null as string | null
})

const companies = ref<{ label: string, value: string }[]>([])
const contacts = ref<{ label: string, value: string }[]>([])
const pipelineId = ref('')

watch(open, async (v) => {
  if (!v) return
  errorMsg.value = ''
  form.title = ''
  form.amount = 0
  form.company_id = null
  form.contact_id = null
  form.expected_close_date = null
  const [{ pipeline, stages }, co, ct] = await Promise.all([
    getDefaultPipeline(),
    listCompanies(),
    listContacts()
  ])
  pipelineId.value = pipeline.id
  form.stage_id = stages[0]?.id || props.stages[0]?.id || ''
  companies.value = co.map(c => ({ label: c.name, value: c.id }))
  contacts.value = ct.map(c => ({
    label: [c.first_name, c.last_name].filter(Boolean).join(' '),
    value: c.id
  }))
})

async function save() {
  if (!form.title || !form.stage_id || !pipelineId.value) return
  loading.value = true
  errorMsg.value = ''
  try {
    await create({
      title: form.title,
      company_id: form.company_id,
      contact_id: form.contact_id,
      stage_id: form.stage_id,
      amount: form.amount,
      expected_close_date: form.expected_close_date,
      pipeline_id: pipelineId.value
    })
    open.value = false
    emit('saved')
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('deals.new')"
    size="md"
  >
    <form
      id="deal-form"
      class="space-y-5"
      @submit.prevent="save"
    >
      <UFormField
        :class="appFormFieldClass"
        :label="t('deals.dealTitle')"
        required
      >
        <UInput
          v-model="form.title"
          class="w-full"
          size="lg"
          :ui="appInputUi"
        />
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('deals.stage')"
      >
        <USelectMenu
          v-model="form.stage_id"
          class="w-full"
          size="lg"
          :ui="appSelectMenuUi"
          :items="stages.map(s => ({ label: s.name, value: s.id }))"
          value-key="value"
        />
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('deals.amount')"
      >
        <UInput
          v-model.number="form.amount"
          class="w-full"
          type="number"
          min="0"
          size="lg"
          :ui="appInputUi"
        />
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('deals.company')"
      >
        <USelectMenu
          v-model="form.company_id"
          class="w-full"
          size="lg"
          :ui="appSelectMenuUi"
          :items="companies"
          value-key="value"
          :placeholder="t('common.optional')"
          searchable
        />
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('deals.contact')"
      >
        <USelectMenu
          v-model="form.contact_id"
          class="w-full"
          size="lg"
          :ui="appSelectMenuUi"
          :items="contacts"
          value-key="value"
          :placeholder="t('common.optional')"
          searchable
        />
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('deals.expectedClose')"
      >
        <UInput
          v-model="form.expected_close_date"
          class="w-full"
          type="date"
          size="lg"
          :ui="appInputUi"
        />
      </UFormField>

      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
      >
        {{ errorMsg }}
      </p>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          type="submit"
          form="deal-form"
          size="lg"
          :loading="loading"
        >
          {{ t('common.create') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
