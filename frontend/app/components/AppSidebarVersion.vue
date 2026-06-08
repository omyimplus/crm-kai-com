<script setup lang="ts">
const { t } = useI18n()
const { versionLabel, versionTitle } = useAppBuildInfo()
</script>

<template>
  <div class="shrink-0 border-t border-gray-200 px-4 py-3 dark:border-gray-800">
    <p
      class="text-xs text-gray-400 dark:text-gray-500"
      :title="versionTitle"
    >
      {{ t('common.version', { version: versionLabel }) }}
    </p>
  </div>
</template>
