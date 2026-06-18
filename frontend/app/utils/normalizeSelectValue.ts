/** USelectMenu may bind the whole item object — normalize to primitive value. */
export function normalizeSelectValue(value: unknown): string | null {
  if (value === null || value === undefined || value === '') return null
  if (typeof value === 'string') return value
  if (typeof value === 'object' && value !== null && 'value' in value) {
    const inner = (value as { value: unknown }).value
    if (inner === null || inner === undefined || inner === '') return null
    return typeof inner === 'string' ? inner : String(inner)
  }
  return null
}
