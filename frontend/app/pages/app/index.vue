<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatCurrency } = useFormat()
const { ensureProfile } = useProfile()
const { stats } = useDeals()

await ensureProfile()

const dealStats = ref({ total: 0, open: 0, won: 0, totalAmount: 0 })

try {
  dealStats.value = await stats()
} catch (e) {
  console.error(e)
}
</script>

<template>
  <div>
    <h1 class="mb-6 text-2xl font-bold font-heading">
      {{ t('dashboard.title') }}
    </h1>
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <UCard>
        <p class="text-sm text-gray-500">
          {{ t('dashboard.totalDeals') }}
        </p>
        <p class="mt-1 text-3xl font-semibold">
          {{ dealStats.total }}
        </p>
      </UCard>
      <UCard>
        <p class="text-sm text-gray-500">
          {{ t('dashboard.openDeals') }}
        </p>
        <p class="mt-1 text-3xl font-semibold">
          {{ dealStats.open }}
        </p>
      </UCard>
      <UCard>
        <p class="text-sm text-gray-500">
          {{ t('dashboard.wonDeals') }}
        </p>
        <p class="mt-1 text-3xl font-semibold">
          {{ dealStats.won }}
        </p>
      </UCard>
      <UCard>
        <p class="text-sm text-gray-500">
          {{ t('dashboard.pipelineValue') }}
        </p>
        <p class="mt-1 text-2xl font-semibold">
          {{ formatCurrency(dealStats.totalAmount) }}
        </p>
      </UCard>
    </div>
    <div class="mt-8 flex flex-wrap gap-3">
      <UButton
        to="/app/contacts"
        icon="i-lucide-users"
      >
        {{ t('nav.contacts') }}
      </UButton>
      <UButton
        to="/app/companies"
        icon="i-lucide-building-2"
        variant="outline"
      >
        {{ t('nav.companies') }}
      </UButton>
      <UButton
        to="/app/deals"
        icon="i-lucide-kanban"
        variant="outline"
      >
        {{ t('dashboard.dealsPipeline') }}
      </UButton>
    </div>
  </div>
</template>
