import type { FlatConfigComposer } from "../node_modules/.pnpm/eslint-flat-config-utils@3.2.0/node_modules/eslint-flat-config-utils/dist/index.mjs"
import { defineFlatConfigs } from "../node_modules/.pnpm/@nuxt+eslint-config@1.16.0_@typescript-eslint+utils@8.62.0_eslint@10.5.0_jiti@2.7.0__ty_3f715d3f176d0af85dede0a1fcf5b2b4/node_modules/@nuxt/eslint-config/dist/flat.mjs"
import type { NuxtESLintConfigOptionsResolved } from "../node_modules/.pnpm/@nuxt+eslint-config@1.16.0_@typescript-eslint+utils@8.62.0_eslint@10.5.0_jiti@2.7.0__ty_3f715d3f176d0af85dede0a1fcf5b2b4/node_modules/@nuxt/eslint-config/dist/flat.mjs"

declare const configs: FlatConfigComposer
declare const options: NuxtESLintConfigOptionsResolved
declare const withNuxt: typeof defineFlatConfigs
export default withNuxt
export { withNuxt, defineFlatConfigs, configs, options }