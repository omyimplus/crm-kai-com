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
      class="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <table class="w-full text-sm">
        <thead class="bg-gray-50 dark:bg-gray-900">
          <tr>
            <th class="text-left p-3 font-medium">
              {{ t('contacts.name') }}
            </th>
            <th class="text-left p-3 font-medium">
              {{ t('contacts.email') }}
            </th>
            <th class="text-left p-3 font-medium">
              {{ t('contacts.company') }}
            </th>
            <th class="text-left p-3 font-medium">
              {{ t('contacts.phone') }}
            </th>
            <th class="p-3" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="c in contacts"
            :key="c.id"
            class="border-t border-gray-200 dark:border-gray-800"
          >
            <td class="p-3">
              <NuxtLink
                :to="`/app/contacts/${c.id}`"
                class="font-medium hover:underline"
              >
                {{ fullName(c) }}
              </NuxtLink>
            </td>
            <td class="p-3 text-gray-600">
              {{ c.email || t('common.empty') }}
            </td>
            <td class="p-3 text-gray-600">
              {{ c.companies?.name || t('common.empty') }}
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
