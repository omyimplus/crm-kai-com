<script setup lang="ts">
import type { OrgCompanyProfile } from '~/types/crm'
import {
  localizedOrgCompanyAddress,
  localizedOrgCompanyName
} from '~/utils/orgCompanyProfile'

const props = defineProps<{
  profile: OrgCompanyProfile
}>()

const emit = defineEmits<{
  edit: [profile: OrgCompanyProfile]
  delete: [profile: OrgCompanyProfile]
}>()

const { t, locale } = useI18n()

const displayCompany = computed(() =>
  localizedOrgCompanyName(props.profile, locale.value)
)

const addressPreview = computed(() =>
  localizedOrgCompanyAddress(props.profile, locale.value)
)
</script>

<template>
  <article
    class="group relative flex flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow duration-200 hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
  >
    <div
      class="absolute inset-x-0 top-0 h-1"
      :class="profile.isDefault
        ? 'bg-menu-section dark:bg-green-400'
        : 'bg-gray-200 dark:bg-gray-700'"
    />

    <div class="flex flex-1 flex-col p-4 pt-5">
      <div class="mb-3 flex items-start justify-between gap-2">
        <div
          class="flex size-11 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-gray-100 bg-gray-50 dark:border-gray-800 dark:bg-gray-800/50"
        >
          <img
            v-if="profile.logoUrl"
            :src="profile.logoUrl"
            alt=""
            class="h-full w-full object-contain"
          >
          <UIcon
            v-else
            name="i-lucide-building-2"
            class="size-5 text-primary"
          />
        </div>

        <UBadge
          v-if="profile.isDefault"
          color="success"
          variant="subtle"
          size="sm"
        >
          {{ t('setup.settings.companyInfo.defaultBadge') }}
        </UBadge>
      </div>

      <div class="min-w-0 flex-1">
        <h3 class="truncate text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ profile.profileName }}
        </h3>

        <p class="mt-1 truncate text-sm font-medium text-gray-700 dark:text-gray-300">
          {{ displayCompany.primary }}
        </p>

        <p
          v-if="displayCompany.secondary"
          class="mt-0.5 truncate text-sm text-gray-500 dark:text-gray-400"
        >
          {{ displayCompany.secondary }}
        </p>

        <p
          v-if="addressPreview"
          class="mt-2 line-clamp-2 text-sm leading-snug text-gray-500 dark:text-gray-400"
        >
          {{ addressPreview }}
        </p>
        <p
          v-else
          class="mt-2 text-sm italic text-gray-400 dark:text-gray-500"
        >
          {{ t('setup.settings.companyInfo.card.noAddress') }}
        </p>
      </div>

      <div class="mt-3 grid grid-cols-2 gap-2">
        <div class="rounded-lg border border-gray-100 bg-gray-50/80 px-2.5 py-2 dark:border-gray-800 dark:bg-gray-800/50">
          <div class="flex items-center gap-1 text-[11px] text-gray-500">
            <UIcon
              name="i-lucide-receipt"
              class="size-3 shrink-0"
            />
            {{ t('setup.settings.companyInfo.taxId') }}
          </div>
          <p class="mt-0.5 truncate text-sm font-semibold tabular-nums text-gray-900 dark:text-gray-100">
            {{ profile.taxId || t('common.empty') }}
          </p>
        </div>
        <div class="rounded-lg border border-gray-100 bg-gray-50/80 px-2.5 py-2 dark:border-gray-800 dark:bg-gray-800/50">
          <div class="flex items-center gap-1 text-[11px] text-gray-500">
            <UIcon
              name="i-lucide-git-branch"
              class="size-3 shrink-0"
            />
            {{ t('setup.settings.companyInfo.taxBranch') }}
          </div>
          <p class="mt-0.5 truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
            {{ profile.taxBranch || t('common.empty') }}
          </p>
        </div>
      </div>

      <div
        v-if="profile.phone || profile.email"
        class="mt-2 space-y-1 text-xs text-gray-500 dark:text-gray-400"
      >
        <p
          v-if="profile.phone"
          class="flex items-center gap-1.5 truncate"
        >
          <UIcon
            name="i-lucide-phone"
            class="size-3 shrink-0"
          />
          {{ profile.phone }}
        </p>
        <p
          v-if="profile.email"
          class="flex items-center gap-1.5 truncate"
        >
          <UIcon
            name="i-lucide-mail"
            class="size-3 shrink-0"
          />
          {{ profile.email }}
        </p>
      </div>
    </div>

    <div class="grid grid-cols-2 gap-2 border-t border-gray-100 px-3 py-2.5 dark:border-gray-800">
      <UButton
        size="sm"
        variant="soft"
        color="neutral"
        icon="i-lucide-pencil"
        class="justify-center rounded-lg"
        @click="emit('edit', profile)"
      >
        {{ t('common.edit') }}
      </UButton>
      <UButton
        size="sm"
        variant="soft"
        color="error"
        icon="i-lucide-trash-2"
        class="justify-center rounded-lg"
        @click="emit('delete', profile)"
      >
        {{ t('common.delete') }}
      </UButton>
    </div>
  </article>
</template>
