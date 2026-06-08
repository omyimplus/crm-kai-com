<script setup lang="ts">
import type { Company } from '~/types/crm'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile } = useProfile()
const { list, remove } = useCompanies()

await ensureProfile()

const companies = ref<Company[]>([])
const loading = ref(true)

async function refresh() {
  loading.value = true
  companies.value = await list()
  loading.value = false
}

await refresh()

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize
} = usePagination(companies)

async function onDelete(id: string) {
  if (!confirm(t('companies.confirmDelete'))) return
  await remove(id)
  await refresh()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">
        {{ t('companies.title') }}
      </h1>
      <UButton
        to="/app/companies/new"
        icon="i-lucide-plus"
      >
        {{ t('companies.new') }}
      </UButton>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!companies.length">
      <p class="text-gray-500">
        {{ t('companies.empty') }}
      </p>
      <UButton
        to="/app/companies/new"
        class="mt-4"
        size="sm"
      >
        {{ t('companies.addFirst') }}
      </UButton>
    </UCard>

    <div
      v-else
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
      <template #head>
        <tr>
          <AppDataTableTh>{{ t('companies.name') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('companies.industry') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('companies.phone') }}</AppDataTableTh>
          <AppDataTableTh />
        </tr>
      </template>

      <AppDataTableRow
        v-for="c in pagedItems"
        :key="c.id"
      >
        <AppDataTableTd>
          <NuxtLink
            :to="`/app/companies/${c.id}`"
            class="font-medium hover:underline"
          >
            {{ c.name }}
          </NuxtLink>
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ c.industry || t('common.empty') }}
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ c.phone || t('common.empty') }}
        </AppDataTableTd>
        <AppDataTableTd align="right">
          <AppIconButton
            icon="i-lucide-trash-2"
            color="error"
            :aria-label="t('common.delete')"
            @click="onDelete(c.id)"
          />
        </AppDataTableTd>
      </AppDataTableRow>
      </AppDataTable>

      <AppPagination
        v-model:page="page"
        embedded
        :total-items="paginationTotal"
        :total-pages="totalPages"
        :range-start="rangeStart"
        :range-end="rangeEnd"
        :page-size="pageSize"
      />
    </div>
  </div>
</template>
