<script setup lang="ts">
import type { OrgCompanyProfile, OrgCompanyProfileInput } from '~/types/crm'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appFormSwitchBoxClass,
  appInputUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  defaultOrgCompanyProfileInput,
  trimOrgCompanyProfileInput
} from '~/utils/orgCompanyProfile'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  profile: OrgCompanyProfile | null
  isFirstProfile: boolean
}>()

const emit = defineEmits<{
  saved: []
}>()

const { t } = useI18n()
const { create, update } = useOrgCompanyProfiles()
const { uploadLogo, removeLogo } = useOrgCompanyLogo()
const {
  previewUrl: logoPreviewUrl,
  changed: logoChanged,
  file: logoFile,
  removed: logoRemoved,
  select: onLogoSelect,
  remove: onLogoRemove,
  reset: resetLogoState
} = useImageUploadState()

const saving = ref(false)
const errorMsg = ref('')

const form = ref<OrgCompanyProfileInput>(defaultOrgCompanyProfileInput())

const isCreate = computed(() => !props.profile)

const modalTitle = computed(() =>
  isCreate.value
    ? t('setup.settings.companyInfo.createTitle')
    : t('setup.settings.companyInfo.editTitle')
)

function resetForm() {
  if (props.profile) {
    form.value = {
      profileName: props.profile.profileName,
      nameEn: props.profile.nameEn,
      nameTh: props.profile.nameTh,
      taxId: props.profile.taxId,
      taxBranch: props.profile.taxBranch,
      phone: props.profile.phone,
      email: props.profile.email,
      website: props.profile.website,
      addressEn: props.profile.addressEn,
      addressTh: props.profile.addressTh,
      isDefault: props.profile.isDefault
    }
    resetLogoState(props.profile.logoUrl)
  } else {
    form.value = defaultOrgCompanyProfileInput(props.isFirstProfile)
    resetLogoState(null)
  }
  errorMsg.value = ''
}

watch(open, (isOpen) => {
  if (isOpen) resetForm()
})

async function buildLogoPatch(
  profileId: string,
  knownLogoUrl: string | null
): Promise<Pick<OrgCompanyProfileInput, 'logoUrl' | 'setLogo'> | null> {
  if (!logoChanged.value) return null

  if (logoRemoved.value && !logoFile.value) {
    await removeLogo(profileId, knownLogoUrl)
    return { setLogo: true, logoUrl: null }
  }

  if (logoFile.value) {
    const url = await uploadLogo(profileId, logoFile.value)
    return { setLogo: true, logoUrl: url }
  }

  return null
}

async function save() {
  const payload = trimOrgCompanyProfileInput(form.value)

  if (!payload.profileName) {
    errorMsg.value = t('setup.settings.companyInfo.profileNameRequired')
    return
  }
  if (!payload.nameEn) {
    errorMsg.value = t('setup.settings.companyInfo.nameEnRequired')
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isCreate.value) {
      const profileId = await create(payload)
      const logoPatch = await buildLogoPatch(profileId, null)
      if (logoPatch) {
        await update(profileId, { ...payload, ...logoPatch })
      }
    } else if (props.profile) {
      const logoPatch = await buildLogoPatch(props.profile.id, props.profile.logoUrl)
      await update(props.profile.id, {
        ...payload,
        ...(logoPatch ?? {})
      })
    }
    open.value = false
    emit('saved')
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="modalTitle"
    size="lg"
  >
    <form
      id="company-profile-form"
      class="space-y-5"
      @submit.prevent="save"
    >
      <div class="grid gap-5 sm:grid-cols-2">
        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.profileName')"
          required
        >
          <UInput
            v-model="form.profileName"
            class="w-full"
            size="lg"
            :placeholder="t('setup.settings.companyInfo.profileNamePlaceholder')"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.nameEn')"
          required
        >
          <UInput
            v-model="form.nameEn"
            class="w-full"
            size="lg"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.nameTh')"
        >
          <UInput
            v-model="form.nameTh"
            class="w-full"
            size="lg"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.taxId')"
        >
          <UInput
            v-model="form.taxId"
            class="w-full"
            size="lg"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.taxBranch')"
        >
          <UInput
            v-model="form.taxBranch"
            class="w-full"
            size="lg"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.phone')"
        >
          <UInput
            v-model="form.phone"
            class="w-full"
            size="lg"
            type="tel"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.email')"
        >
          <UInput
            v-model="form.email"
            class="w-full"
            size="lg"
            type="email"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.website')"
        >
          <UInput
            v-model="form.website"
            class="w-full"
            size="lg"
            type="url"
            :ui="appInputUi"
          />
        </UFormField>
      </div>

      <UFormField :class="appFormFieldClass">
        <AppImageUpload
          preset="companyLogo"
          :preview-url="logoPreviewUrl"
          :label="t('setup.settings.companyInfo.logo')"
          :hint="t('setup.settings.companyInfo.logoHint')"
          @select="onLogoSelect"
          @remove="onLogoRemove"
        >
          <template #preview="{ previewUrl: logoPreview, hasUpload }">
            <div
              class="flex size-20 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-dashed border-gray-300 bg-gray-50 dark:border-gray-600 dark:bg-gray-800/50"
            >
              <img
                v-if="hasUpload && logoPreview"
                :src="logoPreview"
                alt=""
                class="h-full w-full object-contain"
              >
              <UIcon
                v-else
                name="i-lucide-building-2"
                class="size-8 text-gray-400"
              />
            </div>
          </template>
        </AppImageUpload>
      </UFormField>

      <div class="grid gap-5 lg:grid-cols-2">
        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.addressEn')"
        >
          <UTextarea
            v-model="form.addressEn"
            class="w-full"
            :rows="3"
            :ui="appTextareaUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.companyInfo.addressTh')"
        >
          <UTextarea
            v-model="form.addressTh"
            class="w-full"
            :rows="3"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>

      <UFormField :class="appFormFieldClass">
        <div :class="appFormSwitchBoxClass">
          <USwitch
            v-model="form.isDefault"
            :disabled="isFirstProfile && isCreate"
          />
          <span class="text-sm text-gray-600 dark:text-gray-400">
            {{ t('setup.settings.companyInfo.isDefault') }}
          </span>
        </div>
        <p
          v-if="isFirstProfile && isCreate"
          :class="appFormHintClass"
        >
          {{ t('setup.settings.companyInfo.firstDefaultHint') }}
        </p>
      </UFormField>

      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
      >
        {{ errorMsg }}
      </p>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          type="submit"
          form="company-profile-form"
          size="lg"
          :loading="saving"
        >
          {{ isCreate ? t('common.create') : t('common.save') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
