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
      class="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <table class="w-full text-sm">
        <thead class="bg-gray-50 dark:bg-gray-900">
          <tr>
            <th class="text-left p-3 font-medium">
              {{ t('companies.name') }}
            </th>
            <th class="text-left p-3 font-medium">
              {{ t('companies.industry') }}
            </th>
            <th class="text-left p-3 font-medium">
              {{ t('companies.phone') }}
            </th>
            <th class="p-3" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="c in companies"
            :key="c.id"
            class="border-t border-gray-200 dark:border-gray-800"
          >
            <td class="p-3">
              <NuxtLink
                :to="`/app/companies/${c.id}`"
                class="font-medium hover:underline"
              >
                {{ c.name }}
              </NuxtLink>
            </td>
            <td class="p-3 text-gray-600">
              {{ c.industry || t('common.empty') }}
            </td>
            <td class="p-3 text-gray-600">
              {{ c.phone || t('common.empty') }}
            </td>
            <td class="p-3 text-right">
              <UButton
                size="xs"
                color="error"
                variant="ghost"
                icon="i-lucide-trash-2"
                @click="onDelete(c.id)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
