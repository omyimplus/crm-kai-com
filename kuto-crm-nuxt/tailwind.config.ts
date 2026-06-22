import type { Config } from 'tailwindcss'

export default {
  content: [
    './app/components/**/*.{vue,js,ts}',
    './app/layouts/**/*.vue',
    './app/pages/**/*.vue',
    './app/app.vue',
  ],
  theme: {
    extend: {
      colors: {
        background: '#f6f8fb',
        foreground: '#0b1730',
        primary: {
          DEFAULT: '#0b2a5b',
          foreground: '#ffffff',
        },
        muted: {
          DEFAULT: '#e9eef5',
          foreground: '#64748b',
        },
        border: 'rgba(15, 23, 42, 0.10)',
        'input-background': '#f8fafc',
        sidebar: {
          DEFAULT: '#ffffff',
          foreground: '#334155',
          accent: '#eef6ff',
          'accent-foreground': '#0b2a5b',
          border: 'rgba(15, 23, 42, 0.10)',
        },
      },
      fontFamily: {
        sans: ['"Noto Sans Thai"', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      fontWeight: {
        normal: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
        extrabold: '800',
      },
    },
  },
} satisfies Config
