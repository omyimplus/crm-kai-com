// https://nuxt.com/docs/api/configuration/nuxt-config
import { APP_SEMVER } from './app/config/appVersion'
import { getSupabaseRealtimeTransport } from './build/supabaseRealtimeTransport'
import { getGitBuildInfo } from './scripts/gitBuildInfo.mjs'

const gitBuildInfo = getGitBuildInfo()

export default defineNuxtConfig({
  modules: ['@nuxt/eslint', '@nuxt/ui', '@nuxtjs/supabase', '@nuxtjs/i18n'],

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
      cookieKey: 'crm-kai-locale',
      fallbackLocale: 'th'
    },
    vueI18n: 'i18n.config.ts',
    bundle: {
      optimizeTranslationDirective: false
    }
  },

  devtools: { enabled: true },

  sourcemap: false,

  css: ['~/assets/css/main.css'],

  colorMode: {
    preference: 'system',
    fallback: 'light'
  },

  compatibilityDate: '2025-01-15',

  supabase: {
    url: process.env.NUXT_PUBLIC_SUPABASE_URL,
    key: process.env.NUXT_PUBLIC_SUPABASE_KEY
      ?? process.env.NUXT_PUBLIC_SUPABASE_ANON_KEY,
    redirect: false,
    clientOptions: {
      realtime: {
        transport: getSupabaseRealtimeTransport()
      }
    }
  },

  runtimeConfig: {
    public: {
      demoOrgSlug: 'demo',
      appSemver: APP_SEMVER,
      gitCommit: gitBuildInfo.commit,
      gitCommitDate: gitBuildInfo.commitDate
    }
  },

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  },

  vite: {
    optimizeDeps: {
      include: [
        '@vue/devtools-core',
        '@vue/devtools-kit'
      ]
    },
    build: {
      sourcemap: false,
      chunkSizeWarningLimit: 2000,
      rollupOptions: {
        onwarn(warning, defaultHandler) {
          if (warning.message?.includes('__PURE__')) return
          if (warning.message?.includes('Sourcemap is likely to be incorrect')) return
          defaultHandler(warning)
        }
      }
    }
  },

  hooks: {
    'vite:extendConfig'(config) {
      config.build ??= {}
      config.build.sourcemap = false
      const existing = config.build.rollupOptions?.onwarn
      config.build.rollupOptions = {
        ...config.build.rollupOptions,
        onwarn(warning, defaultHandler) {
          if (warning.message?.includes('__PURE__')) return
          if (warning.message?.includes('Sourcemap is likely to be incorrect')) return
          existing?.(warning, defaultHandler)
          defaultHandler(warning)
        }
      }
    }
  }
})
