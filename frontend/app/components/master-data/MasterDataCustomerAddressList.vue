<script setup lang="ts">
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import {
  appFormFieldClass,
  appFormSwitchBoxClass,
  appInputUi,
  appTableBadgeClass,
  appTextareaUi
} from '~/config/appFormUi'

const props = defineProps<{
  modelValue: CustomerCompanyAddressDraft[]
  readonly?: boolean
  /** i18n key suffix: `masterData.customer.{i18nKey}.*` */
  i18nKey: 'ship' | 'bill'
}>()

const emit = defineEmits<{
  'update:modelValue': [value: CustomerCompanyAddressDraft[]]
}>()

const { t } = useI18n()

const addresses = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value)
})

const formOpen = ref(false)
const label = ref('')
const address = ref('')
const isDefault = ref(false)
const editingId = ref<string | null>(null)

const i18nPrefix = computed(() => `masterData.customer.${props.i18nKey}` as const)

function resetForm() {
  formOpen.value = false
  label.value = ''
  address.value = ''
  isDefault.value = false
  editingId.value = null
}

function applyDefaultFlag(
  rows: CustomerCompanyAddressDraft[],
  targetId: string,
  defaultFlag: boolean
): CustomerCompanyAddressDraft[] {
  if (!defaultFlag) {
    return rows.map(row =>
      row.id === targetId ? { ...row, is_default: false } : row
    )
  }
  return rows.map(row => ({
    ...row,
    is_default: row.id === targetId
  }))
}

function openAdd() {
  resetForm()
  isDefault.value = addresses.value.length === 0
  formOpen.value = true
}

function openEdit(row: CustomerCompanyAddressDraft) {
  formOpen.value = true
  editingId.value = row.id
  label.value = row.label
  address.value = row.address
  isDefault.value = row.is_default
}

function saveAddress() {
  const trimmedAddress = address.value.trim()
  if (!trimmedAddress) return

  if (editingId.value) {
    const updated = addresses.value.map(row =>
      row.id === editingId.value
        ? { ...row, label: label.value.trim(), address: trimmedAddress }
        : row
    )
    addresses.value = applyDefaultFlag(updated, editingId.value, isDefault.value)
  } else {
    const id = crypto.randomUUID()
    addresses.value = applyDefaultFlag(
      [
        ...addresses.value,
        {
          id,
          label: label.value.trim(),
          address: trimmedAddress,
          is_default: false
        }
      ],
      id,
      isDefault.value
    )
  }
  resetForm()
}

function setDefault(id: string) {
  addresses.value = addresses.value.map(row => ({
    ...row,
    is_default: row.id === id
  }))
}

function removeAddress(id: string) {
  const wasDefault = addresses.value.some(row => row.id === id && row.is_default)
  const next = addresses.value.filter(row => row.id !== id)
  if (wasDefault && next.length === 1) {
    next[0] = { ...next[0], is_default: true }
  }
  addresses.value = next
}
</script>

<template>
  <div>
    <div class="mb-4 flex justify-end">
      <UButton
        v-if="!readonly"
        variant="soft"
        icon="i-lucide-plus"
        size="sm"
        @click="openAdd"
      >
        {{ t(`${i18nPrefix}.add`) }}
      </UButton>
    </div>

    <p
      v-if="!addresses.length && !formOpen"
      class="text-sm text-gray-500 dark:text-gray-400"
    >
      {{ t(`${i18nPrefix}.empty`) }}
    </p>

    <div
      v-if="addresses.length"
      class="space-y-3"
    >
      <div
        v-for="row in addresses"
        :key="row.id"
        class="flex items-start justify-between gap-3 rounded-xl border border-gray-200 px-4 py-3 dark:border-gray-700"
      >
        <div class="min-w-0">
          <div class="mb-1 flex flex-wrap items-center gap-2">
            <p
              v-if="row.label"
              class="text-sm font-medium"
            >
              {{ row.label }}
            </p>
            <UBadge
              v-if="row.is_default"
              color="primary"
              variant="subtle"
              size="sm"
              :class="appTableBadgeClass"
            >
              {{ t(`${i18nPrefix}.default`) }}
            </UBadge>
          </div>
          <p class="whitespace-pre-wrap text-sm text-gray-600 dark:text-gray-300">
            {{ row.address }}
          </p>
        </div>
        <div class="flex shrink-0 items-center gap-1">
          <UButton
            v-if="!readonly && !row.is_default"
            variant="link"
            color="primary"
            size="xs"
            class="px-1"
            @click="setDefault(row.id)"
          >
            {{ t(`${i18nPrefix}.default`) }}
          </UButton>
          <template v-if="!readonly">
            <AppIconButton
              icon="i-lucide-pencil"
              :aria-label="t('common.edit')"
              @click="openEdit(row)"
            />
            <AppIconButton
              icon="i-lucide-trash-2"
              color="error"
              :aria-label="t('common.delete')"
              @click="removeAddress(row.id)"
            />
          </template>
        </div>
      </div>
    </div>

    <div
      v-if="formOpen"
      class="mt-4 space-y-4 rounded-xl border border-dashed border-gray-300 p-4 dark:border-gray-600"
    >
      <UFormField
        :label="t(`${i18nPrefix}.label`)"
        :class="appFormFieldClass"
      >
        <UInput
          v-model="label"
          :class="appFormFieldClass"
          :ui="appInputUi"
        />
      </UFormField>
      <UFormField
        :label="t(`${i18nPrefix}.address`)"
        required
        :class="appFormFieldClass"
      >
        <UTextarea
          v-model="address"
          :class="appFormFieldClass"
          :ui="appTextareaUi"
          :rows="3"
        />
      </UFormField>
      <UFormField :class="appFormFieldClass">
        <div :class="appFormSwitchBoxClass">
          <USwitch v-model="isDefault" />
          <span class="text-sm text-gray-600 dark:text-gray-400">
            {{ t(`${i18nPrefix}.useAsDefault`) }}
          </span>
        </div>
      </UFormField>
      <div class="flex gap-2">
        <UButton
          size="sm"
          @click="saveAddress"
        >
          {{ editingId ? t('common.save') : t(`${i18nPrefix}.add`) }}
        </UButton>
        <UButton
          size="sm"
          variant="outline"
          color="neutral"
          @click="resetForm"
        >
          {{ t('common.cancel') }}
        </UButton>
      </div>
    </div>
  </div>
</template>
