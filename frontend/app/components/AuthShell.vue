<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
}>()
</script>

<template>
  <div class="auth-shell min-h-screen flex flex-col lg:flex-row">
    <!-- Brand panel — พื้นหลังเขียวอ่อน + content ใน container -->
    <aside
      class="relative hidden lg:flex lg:w-[46%] xl:w-[50%] items-center justify-center overflow-hidden bg-green-50 dark:bg-green-950/40 p-8 xl:p-12 border-r border-green-100 dark:border-green-900"
    >
      <div
        class="pointer-events-none absolute -top-20 -right-20 h-72 w-72 rounded-full bg-green-200/30 blur-2xl dark:bg-green-800/15"
        aria-hidden="true"
      />

      <div class="auth-brand-panel relative z-10 flex w-full max-w-lg flex-col justify-between gap-12 min-h-[min(640px,calc(100vh-4rem))] py-4">
        <div>
          <AppLogo
            variant="full"
            size="lg"
            framed
          />
        </div>

        <div class="space-y-8">
          <div>
            <h2 class="font-heading text-3xl xl:text-4xl font-semibold leading-tight text-gray-900 dark:text-white">
              {{ $t('auth.brandHeadline') }}
            </h2>
            <p class="mt-4 text-base text-gray-600 dark:text-gray-300 leading-relaxed">
              {{ $t('auth.brandDescription') }}
            </p>
          </div>

          <ul class="space-y-4">
            <li
              v-for="key in ['auth.brandFeature1', 'auth.brandFeature2', 'auth.brandFeature3']"
              :key="key"
              class="flex items-start gap-3 text-sm text-gray-700 dark:text-gray-200"
            >
              <span class="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-green-500/15 text-green-700 dark:text-green-400">
                <UIcon
                  name="i-lucide-check"
                  class="h-3.5 w-3.5"
                />
              </span>
              <span>{{ $t(key) }}</span>
            </li>
          </ul>
        </div>

        <p class="text-xs text-gray-500 dark:text-gray-400">
          © {{ new Date().getFullYear() }} {{ $t('common.appName') }}
        </p>
      </div>
    </aside>

    <!-- Form panel -->
    <main class="flex flex-1 flex-col min-h-screen bg-white dark:bg-gray-950">
      <header class="flex items-center justify-between gap-4 px-5 pt-5 lg:px-10 lg:pt-8">
        <AppLogo
          variant="full"
          size="sm"
          class="lg:hidden"
        />
        <div class="ml-auto flex items-center gap-1">
          <ThemeToggle />
          <LocaleSwitcher />
        </div>
      </header>

      <div class="auth-form-panel flex flex-1 items-center justify-center px-5 pb-10 lg:px-10 lg:pb-14">
        <div class="w-full max-w-[420px]">
          <div class="mb-8 hidden lg:block">
            <h1 class="font-heading text-2xl font-semibold text-gray-900 dark:text-white">
              {{ title }}
            </h1>
            <p
              v-if="subtitle"
              class="mt-2 text-sm text-gray-500 dark:text-gray-400"
            >
              {{ subtitle }}
            </p>
          </div>

          <div class="lg:hidden mb-6">
            <h1 class="font-heading text-xl font-semibold text-gray-900 dark:text-white">
              {{ title }}
            </h1>
            <p
              v-if="subtitle"
              class="mt-1.5 text-sm text-gray-500 dark:text-gray-400"
            >
              {{ subtitle }}
            </p>
          </div>

          <div class="rounded-2xl border border-gray-100 bg-gray-50/50 p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900/50 lg:border-0 lg:bg-transparent lg:p-0 lg:shadow-none">
            <slot />
          </div>

          <p
            v-if="$slots.footer"
            class="mt-6 text-center text-sm text-gray-500 dark:text-gray-400"
          >
            <slot name="footer" />
          </p>
        </div>
      </div>
    </main>
  </div>
</template>
