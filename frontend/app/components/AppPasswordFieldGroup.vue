<script setup lang="ts">
import { appFormFieldClass, appFormHintClass } from '~/config/appFormUi'
import {
  analyzePasswordStrength,
  generateStrongPassword,
  passwordsMatch
} from '~/utils/password'

const password = defineModel<string>('password', { required: true })
const confirmPassword = defineModel<string>('confirmPassword', { default: '' })

const props = withDefaults(defineProps<{
  /** true = เว้นว่างได้ (โหมดแก้ไข) */
  optional?: boolean
  disabled?: boolean
  hint?: string
  passwordPlaceholder?: string
  confirmPlaceholder?: string
}>(), {
  optional: false,
  disabled: false
})

const { t } = useI18n()

const passwordInputRef = ref<{ show: () => void } | null>(null)
const confirmInputRef = ref<{ show: () => void } | null>(null)

const fieldsRequired = computed(() => !props.optional)

const strength = computed(() => analyzePasswordStrength(password.value))

const showStrength = computed(() =>
  password.value.length > 0 || !props.optional
)

const matchPassed = computed(() =>
  passwordsMatch(password.value, confirmPassword.value)
)

const showMatchCheck = computed(() =>
  confirmPassword.value.length > 0
)

const strengthBarClass = computed(() => {
  const map: Record<string, string> = {
    weak: 'bg-red-500',
    fair: 'bg-amber-500',
    good: 'bg-lime-500',
    strong: 'bg-green-500'
  }
  return map[strength.value.level] ?? 'bg-gray-200 dark:bg-gray-700'
})

const strengthLabel = computed(() => {
  if (strength.value.level === 'empty') return ''
  return t(`auth.passwordStrength.${strength.value.level}`)
})

const ruleLabels: Record<string, string> = {
  length: 'auth.passwordRule.length',
  upper: 'auth.passwordRule.upper',
  lower: 'auth.passwordRule.lower',
  digit: 'auth.passwordRule.digit',
  symbol: 'auth.passwordRule.symbol'
}

function generate() {
  const value = generateStrongPassword()
  password.value = value
  confirmPassword.value = value
  passwordInputRef.value?.show()
  confirmInputRef.value?.show()
}
</script>

<template>
  <div
    class="space-y-4 rounded-xl border border-gray-200 bg-gray-50/70 p-4 dark:border-gray-700 dark:bg-gray-800/40"
  >
    <UFormField
      :class="appFormFieldClass"
      :label="t('auth.password')"
      :required="fieldsRequired"
    >
      <AppPasswordInput
        ref="passwordInputRef"
        v-model="password"
        :placeholder="passwordPlaceholder ?? t('auth.passwordPlaceholder')"
        :disabled="disabled"
      />
    </UFormField>

    <div
      v-if="showStrength"
      class="space-y-3"
    >
      <div class="space-y-1.5">
        <div class="flex items-center justify-between gap-2 text-xs">
          <span class="font-medium text-gray-600 dark:text-gray-400">
            {{ t('auth.passwordStrengthLabel') }}
          </span>
          <span
            v-if="strengthLabel"
            class="font-medium"
            :class="{
              'text-red-600 dark:text-red-400': strength.level === 'weak',
              'text-amber-600 dark:text-amber-400': strength.level === 'fair',
              'text-lime-600 dark:text-lime-400': strength.level === 'good',
              'text-green-600 dark:text-green-400': strength.level === 'strong'
            }"
          >
            {{ strengthLabel }}
          </span>
        </div>
        <div class="flex gap-1">
          <div
            v-for="i in 4"
            :key="i"
            class="h-1 flex-1 rounded-full transition-colors duration-200"
            :class="i <= strength.segments ? strengthBarClass : 'bg-gray-200 dark:bg-gray-700'"
          />
        </div>
      </div>

      <ul class="grid gap-1.5 sm:grid-cols-2">
        <li
          v-for="rule in strength.rules"
          :key="rule.id"
          class="flex items-center gap-2 text-xs"
        >
          <UIcon
            :name="rule.passed ? 'i-lucide-check' : 'i-lucide-minus'"
            class="size-3.5 shrink-0"
            :class="rule.passed ? 'text-green-600 dark:text-green-400' : 'text-gray-400'"
          />
          <span
            :class="rule.passed
              ? 'text-gray-700 dark:text-gray-300'
              : 'text-gray-500 dark:text-gray-500'"
          >
            {{ t(ruleLabels[rule.id]!) }}
          </span>
        </li>
      </ul>
    </div>

    <UFormField
      :class="appFormFieldClass"
      :label="t('auth.confirmPassword')"
      :required="fieldsRequired"
    >
      <AppPasswordInput
        ref="confirmInputRef"
        v-model="confirmPassword"
        :placeholder="confirmPlaceholder ?? (optional ? t('auth.confirmPasswordOptionalPlaceholder') : t('auth.confirmPasswordPlaceholder'))"
        :disabled="disabled"
      />
    </UFormField>

    <div
      v-if="showMatchCheck"
      class="flex items-center gap-2 text-xs"
    >
      <UIcon
        :name="matchPassed ? 'i-lucide-check' : 'i-lucide-minus'"
        class="size-3.5 shrink-0"
        :class="matchPassed ? 'text-green-600 dark:text-green-400' : 'text-gray-400'"
      />
      <span
        :class="matchPassed
          ? 'text-gray-700 dark:text-gray-300'
          : 'text-gray-500'"
      >
        {{ t('auth.passwordRule.match') }}
      </span>
    </div>

    <UButton
      type="button"
      variant="solid"
      size="md"
      block
      class="rounded-xl font-medium bg-primary text-white hover:bg-blue-600 dark:bg-primary dark:text-white dark:hover:bg-blue-600"
      :disabled="disabled"
      @click="generate"
    >
      {{ t('auth.generateStrongPassword') }}
    </UButton>

    <p
      v-if="hint"
      :class="appFormHintClass"
    >
      {{ hint }}
    </p>
  </div>
</template>
