<template>
  <UColorModeButton
    variant="ghost"
    color="neutral"
  >
    <template #fallback>
      <UButton
        loading
        variant="ghost"
        color="neutral"
        :aria-label="$t('common.theme')"
      />
    </template>
  </UColorModeButton>
</template>
