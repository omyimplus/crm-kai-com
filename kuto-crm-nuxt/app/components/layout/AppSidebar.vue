<script setup lang="ts">
import { ChevronDown } from 'lucide-vue-next'
import { navItems } from '~/data/navigation'
import { tx } from '~/utils/i18n'

const route = useRoute()
const { lang } = useLang()

const isActiveGroup = (index: number) => index === 0 && route.path === '/'
const isActiveSub = (path: string) => route.path === path
</script>

<template>
  <aside class="hidden overflow-y-auto border-r border-sidebar-border bg-sidebar p-4 lg:block">
    <div class="mb-5 flex items-center gap-3 px-2">
      <div class="flex h-14 w-40 items-center rounded-2xl bg-white p-2 shadow-sm ring-1 ring-border">
        <div class="flex flex-col leading-tight">
          <span class="text-sm font-extrabold text-primary">KC KuTo</span>
          <span class="text-[10px] font-semibold uppercase tracking-wider text-emerald-600">CRM</span>
        </div>
      </div>
    </div>

    <nav class="space-y-2">
      <details
        v-for="(item, index) in navItems"
        :key="item.label.en"
        :open="index < 3"
        class="group rounded-2xl"
      >
        <summary
          :class="[
            'flex cursor-pointer list-none items-center gap-3 rounded-2xl px-3 py-2.5',
            isActiveGroup(index)
              ? 'bg-sidebar-accent text-sidebar-accent-foreground'
              : 'hover:bg-slate-50',
          ]"
        >
          <component :is="item.icon" class="size-4 shrink-0" />
          <span class="min-w-0 flex-1 text-sm font-semibold leading-5">
            {{ tx(item.label, lang) }}
          </span>
          <ChevronDown class="size-4 transition group-open:rotate-180" />
        </summary>

        <div class="ml-9 mt-1 space-y-1 border-l border-border pl-3">
          <NuxtLink
            v-for="sub in item.subs"
            :key="sub.en"
            :to="sub.path"
            :class="[
              'block w-full rounded-xl px-2 py-1.5 text-left text-xs leading-5 hover:bg-slate-50 hover:text-primary',
              isActiveSub(sub.path)
                ? 'bg-slate-50 text-primary'
                : 'text-muted-foreground',
            ]"
          >
            {{ tx(sub, lang) }}
          </NuxtLink>
        </div>
      </details>
    </nav>
  </aside>
</template>
