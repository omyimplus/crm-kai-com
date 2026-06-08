<template>
  <header
    class="z-10 flex h-14 shrink-0 items-center justify-between gap-4 border-b border-gray-200 bg-white px-4 dark:border-gray-800 dark:bg-gray-900 lg:px-6"
  >
    <NuxtLink
      to="/app"
      class="shrink-0 transition-opacity hover:opacity-90 lg:hidden"
      :aria-label="$t('common.appName')"
    >
      <AppLogo
        variant="icon"
        size="sm"
      />
    </NuxtLink>

    <div class="ml-auto flex items-center gap-2">
      <ThemeToggle />
      <LocaleSwitcher />
      <UserMenu />
    </div>
  </header>
</template>
