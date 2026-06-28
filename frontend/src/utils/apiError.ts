import axios from 'axios'
import type { ApiResponse } from '@/types'

export function getApiErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError(error)) {
    const responseData = error.response?.data as ApiResponse | string | undefined

    if (typeof responseData === 'string' && responseData.trim()) {
      return responseData
    }

    if (responseData && typeof responseData === 'object') {
      const message = responseData.message || responseData.msg || (typeof responseData.detail === 'string' ? responseData.detail : undefined)
      if (typeof message === 'string' && message.trim()) {
        return message
      }
      if (Array.isArray(responseData.detail)) {
        const detailMessages = responseData.detail
          .map((item) => {
            const field = Array.isArray(item.loc) ? item.loc.filter(part => part !== 'body').join('.') : ''
            return [field, item.msg].filter(Boolean).join(': ')
          })
          .filter(Boolean)
        if (detailMessages.length > 0) {
          return detailMessages.join('；')
        }
      }
    }

    if (error.message?.trim()) {
      return error.message
    }
  }

  if (error instanceof Error && error.message.trim()) {
    return error.message
  }

  return fallback
}
