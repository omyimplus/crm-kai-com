export function kutoLeadStatusBadgeClass(statusKey: string): string {
  if (statusKey.includes('newCustomer') || statusKey.includes('.new')) return 'bg-blue-50 text-blue-700 ring-blue-200/80'
  if (statusKey.includes('contacted')) return 'bg-sky-50 text-sky-700 ring-sky-200/80'
  if (statusKey.includes('qualified') || statusKey.includes('review')) return 'bg-violet-50 text-violet-700 ring-violet-200/80'
  if (statusKey.includes('failed')) return 'bg-red-50 text-red-700 ring-red-200/80'
  if (statusKey.includes('followUp') || statusKey.includes('pending')) return 'bg-amber-50 text-amber-700 ring-amber-200/80'
  if (statusKey.includes('losingInterest')) return 'bg-orange-50 text-orange-700 ring-orange-200/80'
  if (statusKey.includes('converted')) return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

export function kutoLeadPriorityBadgeClass(priorityKey: string): string {
  if (priorityKey.includes('urgent')) return 'bg-red-50 text-red-700 ring-red-200/80'
  if (priorityKey.includes('high')) return 'bg-orange-50 text-orange-700 ring-orange-200/80'
  if (priorityKey.includes('normal')) return 'bg-sky-50 text-sky-700 ring-sky-200/80'
  if (priorityKey.includes('low')) return 'bg-gray-50 text-gray-500 ring-gray-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

export function kutoLeadSourceBadgeClass(sourceKey: string): string {
  if (sourceKey.includes('website')) return 'bg-blue-50 text-blue-700 ring-blue-200/80'
  if (sourceKey.includes('lineOa')) return 'bg-violet-50 text-violet-700 ring-violet-200/80'
  if (sourceKey.includes('facebook')) return 'bg-indigo-50 text-indigo-700 ring-indigo-200/80'
  if (sourceKey.includes('marketplace')) return 'bg-amber-50 text-amber-700 ring-amber-200/80'
  if (sourceKey.includes('tender')) return 'bg-teal-50 text-teal-700 ring-teal-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}
