<script setup lang="ts">
import { appInputUi } from '~/config/appFormUi'

const model = defineModel<string>({ required: true })

const props = withDefaults(defineProps<{
  placeholder?: string
  disabled?: boolean
  autocomplete?: string
}>(), {
  autocomplete: 'new-password',
  disabled: false
})

const { t } = useI18n()
const toast = useToast()

const visible = ref(false)
const copied = ref(false)

const inputType = computed(() => (visible.value ? 'text' : 'password'))

async function copyValue() {
  if (!model.value || props.disabled) return
  try {
    await navigator.clipboard.writeText(model.value)
    copied.value = true
    toast.add({
      title: t('auth.passwordCopied'),
      color: 'success',
      duration: 2000
    })
    setTimeout(() => {
      copied.value = false
    }, 2000)
  } catch {
    toast.add({
      title: t('auth.passwordCopyFailed'),
      color: 'error',
      duration: 2500
    })
  }
}

defineExpose({
  show: () => { visible.value = true },
  hide: () => { visible.value = false }
})
</script>

<template>
  <div class="relative w-full">
    <UInput
      v-model="model"
      class="w-full"
      :class="{ 'font-mono tracking-wide': visible && model }"
      :type="inputType"
      :autocomplete="autocomplete"
      size="lg"
      :ui="{ ...appInputUi, base: `${appInputUi.base} pe-24` }"
      :placeholder="placeholder"
      :disabled="disabled"
    />
    <div
      class="absolute inset-y-0 right-2 flex items-center gap-0.5"
      :class="disabled ? 'pointer-events-none opacity-50' : ''"
    >
      <UButton
        type="button"
        variant="ghost"
        color="neutral"
        size="sm"
        square
        class="rounded-lg"
        :icon="visible ? 'i-lucide-eye-off' : 'i-lucide-eye'"
        :aria-label="visible ? t('auth.hidePassword') : t('auth.showPassword')"
        :disabled="disabled || !model"
        @click="visible = !visible"
      />
      <UButton
        type="button"
        variant="ghost"
        color="neutral"
        size="sm"
        square
        class="rounded-lg"
        :icon="copied ? 'i-lucide-check' : 'i-lucide-copy'"
        :aria-label="t('auth.copyPassword')"
        :disabled="disabled || !model"
        @click="copyValue"
      />
    </div>
  </div>
</template>
