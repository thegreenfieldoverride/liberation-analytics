import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Liberation Analytics Dashboard',
  description: 'Manage Liberation Analytics tokens and services',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="bg-gray-50 text-gray-900">{children}</body>
    </html>
  )
}