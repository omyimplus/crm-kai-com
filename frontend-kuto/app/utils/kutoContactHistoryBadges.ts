export function kutoContactHistoryStatusBadgeClass(statusKey: string): string {
  if (statusKey.includes('completed')) return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  if (statusKey.includes('upcoming')) return 'bg-sky-50 text-sky-700 ring-sky-200/80'
  if (statusKey.includes('overdue')) return 'bg-red-50 text-red-700 ring-red-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

export function kutoContactHistoryTypeColor(typeKey: string): string {
  if (typeKey.includes('call')) return '#17A8A3'
  if (typeKey.includes('email')) return '#3B82F6'
  if (typeKey.includes('meeting')) return '#8B5CF6'
  if (typeKey.includes('onlineMeeting')) return '#6366F1'
  if (typeKey.includes('line')) return '#10B981'
  if (typeKey.includes('followUp')) return '#F59E0B'
  return '#64748B'
}
