export function kutoContactRoleBadgeClass(roleKey: string): string {
  if (roleKey.includes('decisionMaker')) return 'bg-rose-50 text-rose-700 ring-rose-200/80'
  if (roleKey.includes('purchasing')) return 'bg-amber-50 text-amber-800 ring-amber-200/80'
  if (roleKey.includes('it')) return 'bg-sky-50 text-sky-700 ring-sky-200/80'
  if (roleKey.includes('influencer')) return 'bg-violet-50 text-violet-700 ring-violet-200/80'
  if (roleKey.includes('gatekeeper')) return 'bg-indigo-50 text-indigo-700 ring-indigo-200/80'
  if (roleKey.includes('user')) return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

export function kutoContactStatusBadgeClass(statusKey: string): string {
  if (statusKey.includes('active')) return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  return 'bg-gray-100 text-gray-600 ring-gray-200/80'
}
