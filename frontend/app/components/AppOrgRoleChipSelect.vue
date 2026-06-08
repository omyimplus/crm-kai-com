<script setup lang="ts">
import type { OrgRole } from '~/types/crm'

const model = defineModel<string[]>({ required: true })

const props = withDefaults(defineProps<{
  options: OrgRole[]
  disabled?: boolean
}>(), {
  disabled: false
})

const { t } = useI18n()

const sortedOptions = computed(() =>
  [...props.options].sort((a, b) => a.label.localeCompare(b.label, 'th'))
)

function isSelected(id: string) {
  return model.value.includes(id)
}

function toggle(id: string) {
  if (props.disabled) return
  if (isSelected(id)) {
    model.value = model.value.filter(roleId => roleId !== id)
  } else {
    model.value = [...model.value, id]
  }
}
</script>

<template>
  <div
    v-if="sortedOptions.length"
    class="flex flex-wrap gap-2"
    role="group"
  >
    <button
      v-for="role in sortedOptions"
      :key="role.id"
      type="button"
      class="rounded-full transition-opacity focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50 disabled:cursor-not-allowed disabled:opacity-50"
      :disabled="disabled"
      :aria-pressed="isSelected(role.id)"
      @click="toggle(role.id)"
    >
      <UBadge
        :color="isSelected(role.id) ? 'primary' : 'neutral'"
        :variant="isSelected(role.id) ? 'solid' : 'subtle'"
        size="lg"
        class="cursor-pointer rounded-full px-3 py-1.5"
      >
        {{ role.label }}
      </UBadge>
    </button>
  </div>
  <p
    v-else
    class="rounded-xl border border-dashed border-gray-200 px-4 py-3 text-sm text-gray-500 dark:border-gray-700"
  >
    {{ t('setup.systemUsers.noOrgRolesAvailable') }}
  </p>
</template>
