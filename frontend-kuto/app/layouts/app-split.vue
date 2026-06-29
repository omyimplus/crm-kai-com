<template>
  <div class="kuto-app flex h-dvh overflow-hidden bg-shell-bg">
    <KutoSidebar />

    <div class="flex min-h-0 min-w-0 w-full flex-1 flex-col">
      <KutoHeader />
      <!-- ไม่มี padding — หน้า split จัด scroll + panel ขวาเอง -->
      <div class="flex min-h-0 flex-1 overflow-hidden bg-shell-bg">
        <slot />
      </div>
    </div>
  </div>
</template>
