export type DeviceType = 'desktop' | 'mobile' | 'tablet' | 'unknown'

export interface ParsedUserAgent {
  deviceType: DeviceType
  browser: string
}

export function parseUserAgent(userAgent: string): ParsedUserAgent {
  const ua = userAgent.trim()
  if (!ua) {
    return { deviceType: 'unknown', browser: 'unknown' }
  }

  let deviceType: DeviceType = 'desktop'
  if (/ipad|tablet|playbook|silk/i.test(ua)) {
    deviceType = 'tablet'
  } else if (/mobile|iphone|ipod|android.*mobile|windows phone/i.test(ua)) {
    deviceType = 'mobile'
  } else if (/android/i.test(ua)) {
    deviceType = 'tablet'
  }

  let browser = 'unknown'
  if (/edg\//i.test(ua)) {
    browser = 'Edge'
  } else if (/opr\//i.test(ua) || /opera/i.test(ua)) {
    browser = 'Opera'
  } else if (/firefox\//i.test(ua)) {
    browser = 'Firefox'
  } else if (/chrome\//i.test(ua) && !/edg\//i.test(ua)) {
    browser = 'Chrome'
  } else if (/safari\//i.test(ua) && !/chrome\//i.test(ua)) {
    browser = 'Safari'
  }

  return { deviceType, browser }
}
