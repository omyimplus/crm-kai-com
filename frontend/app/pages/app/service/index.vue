<script setup lang="ts">
import type { Service } from '~/types/crm'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatCurrency } = useFormat()
const { ensureProfile } = useProfile()
const { list } = useServices()

await ensureProfile()

const services = ref<Service[]>([])
const loading = ref(true)

try {
  services.value = await list()
} catch (error) {
  console.error(error)
  services.value = []
} finally {
  loading.value = false
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('appMenu.service.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('appMenu.service.listSubtitle') }}
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        to="/app/service/new"
      >
        {{ t('appMenu.service.create') }}
      </UButton>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!services.length">
      <p class="text-gray-500">
        {{ t('appMenu.service.empty') }}
      </p>
      <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
        {{ t('appMenu.service.description') }}
      </p>
    </UCard>

    <div
      v-else
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
        <template #head>
          <tr>
            <AppDataTableTh>{{ t('appMenu.service.fields.code') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('appMenu.service.fields.name') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('appMenu.service.fields.kind') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('appMenu.service.fields.listPrice') }}</AppDataTableTh>
          </tr>
        </template>
        <AppDataTableRow
          v-for="row in services"
          :key="row.id"
        >
          <AppDataTableTd>{{ row.service_code }}</AppDataTableTd>
          <AppDataTableTd>{{ row.name }}</AppDataTableTd>
          <AppDataTableTd muted>
            {{ t(`appMenu.service.options.kind.${row.service_kind}`) }}
          </AppDataTableTd>
          <AppDataTableTd muted>
            {{ formatCurrency(row.list_price) }}
          </AppDataTableTd>
        </AppDataTableRow>
      </AppDataTable>
    </div>
  </div>
</template>
