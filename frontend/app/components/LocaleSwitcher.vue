<script setup lang="ts">
import { localeFlagByCode, type LocaleFlagCode } from '~/config/localeFlags'

const { locale, locales, setLocale, t } = useI18n()

const localeList = computed(() => locales.value as { code: LocaleFlagCode, name?: string }[])

const otherLocale = computed(() =>
  localeList.value.find(loc => loc.code !== locale.value) ?? localeList.value[0]
)

function flagSrc(code: string) {
  return localeFlagByCode[code as LocaleFlagCode] ?? localeFlagByCode.th
}

async function toggleLocale() {
  const next = otherLocale.value
  if (next && next.code !== locale.value) {
    await setLocale(next.code)
  }
}
</script>

<template>
  <button
    v-if="otherLocale"
    type="button"
    class="rounded-lg border border-gray-200 bg-gray-50/80 p-1 transition-opacity hover:opacity-90 dark:border-gray-700 dark:bg-gray-800/50"
    :aria-label="t('common.switchLanguage', { language: otherLocale.name || otherLocale.code })"
    @click="toggleLocale"
  >
    <img
      :src="flagSrc(otherLocale.code)"
      :alt="otherLocale.name || otherLocale.code"
      width="28"
      height="20"
      class="block h-5 w-7 rounded-sm object-cover"
      loading="lazy"
    />
  </button>
</template>
