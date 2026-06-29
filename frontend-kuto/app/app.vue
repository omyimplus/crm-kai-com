<script setup lang="ts">
const { locale } = useI18n()

const fontsUrl =
  'https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Thai:wght@400;500;600&display=swap'

useHead({
  meta: [{ name: 'viewport', content: 'width=device-width, initial-scale=1' }],
  link: [
    { rel: 'icon', href: '/images/logo/logo-kai-com-crm-icon.webp', type: 'image/webp' },
    { rel: 'stylesheet', href: fontsUrl }
  ],
  htmlAttrs: {
    lang: locale
  }
})

useSeoMeta({
  title: 'KC KuTo CRM',
  description: 'CRM Kai — KuTo UI track'
})
</script>

<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
