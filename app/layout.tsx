import type { Metadata } from "next"
import { Inter } from "next/font/google"

import { ThemeProvider } from "@/components/theme-provider"
import { Toaster } from "@/components/ui/sonner"

import "./globals.css"
import "reactflow/dist/style.css"

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
})

export const metadata: Metadata = {
  title: "Manager DinastiAPI - Gerenciamento de Instâncias WhatsApp",
  description:
    "Sistema de gerenciamento premium para instâncias WhatsApp Business API via DinastiAPI Gateway",
  keywords: ["whatsapp", "api", "dinastiapi", "business", "manager"],
  authors: [{ name: "Setup Automatizado" }],
  openGraph: {
    title: "Manager DinastiAPI",
    description: "Gerenciamento de Instâncias WhatsApp Business",
    type: "website",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <body className={`${inter.variable} font-sans antialiased`}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
          storageKey="dinastiapi-theme"
        >
          {children}
          <Toaster position="top-right" richColors closeButton />
        </ThemeProvider>
      </body>
    </html>
  )
}
