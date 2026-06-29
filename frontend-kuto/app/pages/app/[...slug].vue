<script setup lang="ts">
definePageMeta({ layout: 'app' })

const { t } = useI18n()
</script>

<template>
  <div class="flex flex-col items-center justify-center rounded-xl border border-shell-border bg-shell-card py-24 text-center">
    <UIcon
      name="i-lucide-sparkles"
      class="mb-3 size-10 text-shell-muted opacity-50"
    />
    <p class="font-semibold text-shell-fg">
      {{ t('kuto.header.comingSoon') }}
    </p>
  </div>
</template>
