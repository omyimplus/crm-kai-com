// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: ['@nuxt/eslint', '@nuxt/ui', '@nuxtjs/supabase', '@nuxtjs/i18n'],

  devServer: {
    port: 3001
  },

  i18n: {
    defaultLocale: 'th',
    locales: [
      { code: 'th', language: 'th-TH', name: 'ไทย', file: 'th.json' },
      { code: 'en', language: 'en-US', name: 'English', file: 'en.json' }
    ],
    lazy: true,
    langDir: 'locales',
    strategy: 'no_prefix',
    detectBrowserLanguage: {
      cookieKey: 'crm-kai-kuto-locale',
      fallbackLocale: 'th'
    },
    vueI18n: 'i18n.config.ts',
    bundle: {
      optimizeTranslationDirective: false
    }
  },

  devtools: { enabled: true },

  css: ['~/assets/css/main.css'],

  colorMode: {
    preference: 'light',
    fallback: 'light'
  },

  compatibilityDate: '2025-01-15',

  supabase: {
    url: process.env.NUXT_PUBLIC_SUPABASE_URL,
    key: process.env.NUXT_PUBLIC_SUPABASE_KEY
      ?? process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY,
    redirect: false
  },

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})
