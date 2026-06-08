<script setup lang="ts">
import type { Contact } from '~/types/crm'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile } = useProfile()
const { list, remove } = useContacts()

await ensureProfile()

const contacts = ref<Contact[]>([])
const loading = ref(true)

async function refresh() {
  loading.value = true
  contacts.value = await list()
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
} = usePagination(contacts)

async function onDelete(id: string) {
  if (!confirm(t('contacts.confirmDelete'))) return
  await remove(id)
  await refresh()
}

function fullName(c: Contact) {
  return [c.first_name, c.last_name].filter(Boolean).join(' ')
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">
        {{ t('contacts.title') }}
      </h1>
      <UButton
        to="/app/contacts/new"
        icon="i-lucide-plus"
      >
        {{ t('contacts.new') }}
      </UButton>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!contacts.length">
      <p class="text-gray-500">
        {{ t('contacts.empty') }}
      </p>
      <UButton
        to="/app/contacts/new"
        class="mt-4"
        size="sm"
      >
        {{ t('contacts.addFirst') }}
      </UButton>
    </UCard>

    <div
      v-else
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
      <template #head>
        <tr>
          <AppDataTableTh>{{ t('contacts.name') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('contacts.email') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('contacts.company') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('contacts.phone') }}</AppDataTableTh>
          <AppDataTableTh />
        </tr>
      </template>

      <AppDataTableRow
        v-for="c in pagedItems"
        :key="c.id"
      >
        <AppDataTableTd>
          <NuxtLink
            :to="`/app/contacts/${c.id}`"
            class="font-medium hover:underline"
          >
            {{ fullName(c) }}
          </NuxtLink>
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ c.email || t('common.empty') }}
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ c.companies?.name || t('common.empty') }}
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
