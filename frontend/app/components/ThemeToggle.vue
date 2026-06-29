<script setup lang="ts">
import { appHeaderIconBtnClass } from '~/config/appHeaderUi'

const { t } = useI18n()
const colorMode = useColorMode()

const isDark = computed(() => colorMode.value === 'dark')

function toggle() {
  colorMode.preference = isDark.value ? 'light' : 'dark'
}
</script>

<template>
  <button
    type="button"
    :class="appHeaderIconBtnClass"
    :aria-label="t('common.theme')"
    :title="t('common.theme')"
    @click="toggle"
  >
    <UIcon
      :name="isDark ? 'i-lucide-sun' : 'i-lucide-moon'"
      class="size-5"
    />
  </button>
</template>
