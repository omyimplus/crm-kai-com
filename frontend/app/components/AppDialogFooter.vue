<script setup lang="ts">
defineEmits<{ cancel: [] }>()
</script>

<template>
  <div class="flex w-full flex-col-reverse gap-2 sm:flex-row sm:justify-end">
    <UButton
      class="w-full sm:w-auto"
      variant="outline"
      color="neutral"
      size="lg"
      @click="$emit('cancel')"
    >
      <slot name="cancel">
        {{ $t('common.cancel') }}
      </slot>
    </UButton>
    <slot />
  </div>
</template>
