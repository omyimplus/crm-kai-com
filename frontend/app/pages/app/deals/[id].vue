<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatCurrency } = useFormat()
const route = useRoute()
const dealId = String(route.params.id)

const { ensureProfile } = useProfile()
const { get, getDefaultPipeline, update, remove } = useDeals()

await ensureProfile()

const deal = await get(dealId)
const { stages } = await getDefaultPipeline()

const loading = ref(false)
const errorMsg = ref('')

const form = reactive({
  title: deal.title,
  stage_id: deal.stage_id,
  amount: Number(deal.amount),
  expected_close_date: deal.expected_close_date
})

function statusLabel(status: string) {
  const key = `deals.status.${status}` as 'deals.status.open' | 'deals.status.won' | 'deals.status.lost'
  return t(key)
}

async function save() {
  loading.value = true
  errorMsg.value = ''
  try {
    await update(dealId, {
      title: form.title,
      stage_id: form.stage_id,
      amount: form.amount,
      expected_close_date: form.expected_close_date
    })
    await navigateTo('/app/deals')
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    loading.value = false
  }
}

async function onDelete() {
  if (!confirm(t('deals.confirmDelete'))) return
  await remove(dealId)
  await navigateTo('/app/deals')
}
</script>

<template>
  <div class="max-w-2xl">
    <div class="flex items-start justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold">
          {{ deal.title }}
        </h1>
        <p class="text-gray-500 mt-1">
          {{ formatCurrency(Number(deal.amount), deal.currency) }}
          · {{ deal.pipeline_stages?.name }}
        </p>
      </div>
      <UBadge :color="deal.status === 'won' ? 'success' : deal.status === 'lost' ? 'error' : 'primary'">
        {{ statusLabel(deal.status) }}
      </UBadge>
    </div>

    <UCard class="mb-4">
      <dl class="grid grid-cols-2 gap-4 text-sm">
        <div>
          <dt class="text-gray-500">
            {{ t('deals.company') }}
          </dt>
          <dd>{{ deal.companies?.name || t('common.empty') }}</dd>
        </div>
        <div>
          <dt class="text-gray-500">
            {{ t('deals.contact') }}
          </dt>
          <dd>
            {{
              deal.contacts
                ? [deal.contacts.first_name, deal.contacts.last_name].filter(Boolean).join(' ')
                : t('common.empty')
            }}
          </dd>
        </div>
      </dl>
    </UCard>

    <UCard>
      <template #header>
        <h2 class="font-semibold">
          {{ t('deals.edit') }}
        </h2>
      </template>
      <form
        class="space-y-4"
        @submit.prevent="save"
      >
        <UFormField :label="t('deals.dealTitle')">
          <UInput v-model="form.title" />
        </UFormField>
        <UFormField :label="t('deals.stage')">
          <USelectMenu
            v-model="form.stage_id"
            :items="stages.map(s => ({ label: s.name, value: s.id }))"
            value-key="value"
          />
        </UFormField>
        <UFormField :label="t('deals.amount')">
          <UInput
            v-model.number="form.amount"
            type="number"
          />
        </UFormField>
        <UFormField :label="t('deals.expectedClose')">
          <UInput
            v-model="form.expected_close_date"
            type="date"
          />
        </UFormField>
        <p
          v-if="errorMsg"
          class="text-sm text-red-500"
        >
          {{ errorMsg }}
        </p>
        <div class="flex gap-2">
          <UButton
            type="submit"
            :loading="loading"
          >
            {{ t('common.save') }}
          </UButton>
          <UButton
            to="/app/deals"
            variant="outline"
            color="neutral"
          >
            {{ t('common.back') }}
          </UButton>
          <UButton
            color="error"
            variant="ghost"
            @click="onDelete"
          >
            {{ t('common.delete') }}
          </UButton>
        </div>
      </form>
    </UCard>
  </div>
</template>
