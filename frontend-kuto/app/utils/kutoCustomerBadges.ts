export function kutoCustomerTierBadgeClass(tierKey: string): string {
  if (tierKey.includes('platinum')) return 'bg-slate-800 text-white ring-slate-700'
  if (tierKey.includes('gold')) return 'bg-amber-50 text-amber-800 ring-amber-200/80'
  if (tierKey.includes('silver')) return 'bg-gray-100 text-gray-700 ring-gray-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

export function kutoCustomerTypeBadgeClass(typeKey: string): string {
  if (typeKey.includes('enterprise')) return 'bg-indigo-50 text-indigo-700 ring-indigo-200/80'
  if (typeKey.includes('keyAccount')) return 'bg-violet-50 text-violet-700 ring-violet-200/80'
  if (typeKey.includes('sme')) return 'bg-sky-50 text-sky-700 ring-sky-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

export function kutoCustomerRenewalBadgeClass(renewalKey: string): string {
  if (renewalKey.includes('days30')) return 'bg-amber-50 text-amber-800 ring-amber-200/80'
  if (renewalKey.includes('atRisk')) return 'bg-red-50 text-red-700 ring-red-200/80'
  if (renewalKey.includes('ok')) return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  return 'bg-gray-50 text-gray-500 ring-gray-200/80'
}

export function kutoCustomerHealthColor(score: number): string {
  if (score >= 80) return '#10B981'
  if (score >= 50) return '#F59E0B'
  return '#EF4444'
}
