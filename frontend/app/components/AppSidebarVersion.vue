<script setup lang="ts">
import { APP_VERSION } from '~/config/appVersion'

const { t } = useI18n()
</script>

<template>
  <div class="shrink-0 border-t border-gray-200 px-4 py-3 dark:border-gray-800">
    <p class="text-xs text-gray-400 dark:text-gray-500">
      {{ t('common.version', { version: APP_VERSION }) }}
    </p>
  </div>
</template>
