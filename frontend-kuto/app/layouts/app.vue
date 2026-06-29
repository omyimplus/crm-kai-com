<template>
  <div class="kuto-app flex h-dvh overflow-hidden bg-shell-bg">
    <KutoSidebar />

    <div class="flex min-h-0 min-w-0 w-full flex-1 flex-col">
      <KutoHeader />
      <main class="min-h-0 flex-1 overflow-y-auto bg-shell-bg p-4">
        <slot />
      </main>
    </div>
  </div>
</template>
