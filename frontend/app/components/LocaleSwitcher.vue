<script setup lang="ts">
import { appHeaderControlClass } from '~/config/appHeaderUi'

const { locale, setLocale } = useI18n()

type AppLocale = 'th' | 'en'

const locales: AppLocale[] = ['th', 'en']

async function pick(code: AppLocale) {
  if (locale.value !== code) {
    await setLocale(code)
  }
}
</script>

<template>
  <div
    :class="[appHeaderControlClass, 'flex shrink-0 p-1']"
    role="group"
    :aria-label="$t('common.language')"
  >
    <button
      v-for="code in locales"
      :key="code"
      type="button"
      class="rounded-xl px-2.5 py-1.5 text-sm font-bold transition sm:px-3"
      :class="locale === code
        ? 'bg-primary text-white'
        : 'text-shell-muted hover:text-shell-fg'"
      :aria-pressed="locale === code"
      :aria-label="code === 'th' ? 'ภาษาไทย' : 'English'"
      @click="pick(code)"
    >
      {{ code.toUpperCase() }}
    </button>
  </div>
</template>
