<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const route = useRoute()
const isEdit = computed(() => !!route.params.id && route.params.id !== 'new')
const companyId = computed(() => (isEdit.value ? String(route.params.id) : null))

const { ensureProfile } = useProfile()
const { get, create, update } = useCompanies()

await ensureProfile()

const loading = ref(false)
const errorMsg = ref('')

const form = reactive({
  name: '',
  industry: '',
  website: '',
  phone: '',
  address: ''
})

if (isEdit.value && companyId.value) {
  const c = await get(companyId.value)
  form.name = c.name
  form.industry = c.industry || ''
  form.website = c.website || ''
  form.phone = c.phone || ''
  form.address = c.address || ''
}

async function save() {
  loading.value = true
  errorMsg.value = ''
  try {
    const payload = {
      name: form.name,
      industry: form.industry || null,
      website: form.website || null,
      phone: form.phone || null,
      address: form.address || null
    }
    if (isEdit.value && companyId.value) {
      await update(companyId.value, payload)
    } else {
      await create(payload)
    }
    await navigateTo('/app/companies')
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="max-w-xl">
    <h1 class="text-2xl font-bold mb-6">
      {{ isEdit ? t('companies.edit') : t('companies.new') }}
    </h1>
    <UCard>
      <form
        class="space-y-4"
        @submit.prevent="save"
      >
        <UFormField
          :label="t('companies.name')"
          required
        >
          <UInput v-model="form.name" />
        </UFormField>
        <UFormField :label="t('companies.industry')">
          <UInput v-model="form.industry" />
        </UFormField>
        <UFormField :label="t('companies.website')">
          <UInput v-model="form.website" />
        </UFormField>
        <UFormField :label="t('companies.phone')">
          <UInput v-model="form.phone" />
        </UFormField>
        <UFormField :label="t('companies.address')">
          <UTextarea v-model="form.address" />
        </UFormField>
        <p
          v-if="errorMsg"
          class="text-sm text-red-500"
        >
          {{ errorMsg }}
        </p>
        <div class="flex gap-2">
          <UButton
            type="submit"
            :loading="loading"
          >
            {{ t('common.save') }}
          </UButton>
          <UButton
            to="/app/companies"
            variant="outline"
            color="neutral"
          >
            {{ t('common.cancel') }}
          </UButton>
        </div>
      </form>
    </UCard>
  </div>
</template>
