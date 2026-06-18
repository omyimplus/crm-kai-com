<script setup lang="ts">
import { partnerDisplayLabel, partnerToFormInput } from '~/utils/masterPartner'

const props = defineProps<{
  partnerId: string
}>()

const { t } = useI18n()
const { get } = usePartners()

const loading = ref(true)
const form = ref(partnerToFormInput({
  id: '',
  org_id: '',
  partner_code: '',
  name: '',
  partner_type: 'distributor',
  tier: 'silver',
  partner_since: null,
  status: 'active',
  contact_person: '',
  email: '',
  phone: '',
  website: null,
  commission_rate: 0,
  created_at: '',
  updated_at: ''
}))
const deleteOpen = ref(false)

try {
  const row = await get(props.partnerId)
  form.value = partnerToFormInput(row)
} catch (e) {
  console.error(e)
  await navigateTo('/app/partner')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/partner')
}
</script>

<template>
  <div>
    <UButton
      to="/app/partner"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('common.back') }}
    </UButton>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <div
      v-else
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
    >
      <div class="min-w-0 space-y-6">
        <h1 class="text-2xl font-bold font-heading">
          {{ partnerDisplayLabel(form) }}
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.partner.viewSubtitle') }}
        </p>

        <MasterDataPartnerForm
          v-model="form"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.partner.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/partner/${partnerId}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            block
            class="mt-2"
            color="error"
            variant="soft"
            icon="i-lucide-trash-2"
            @click="deleteOpen = true"
          >
            {{ t('common.delete') }}
          </UButton>
        </UCard>
      </aside>
    </div>

    <MasterDataPartnerDeleteModal
      v-model:open="deleteOpen"
      :partner-id="partnerId"
      :partner-name="partnerDisplayLabel(form)"
      @deleted="onDeleted"
    />
  </div>
</template>
