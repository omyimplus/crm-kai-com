<template>
  <div class="min-h-screen bg-background text-foreground">
    <div class="grid min-h-screen lg:grid-cols-[310px_1fr]">
      <LayoutAppSidebar />
      <main class="min-w-0">
        <LayoutAppHeader />
        <slot />
      </main>
    </div>
  </div>
</template>
