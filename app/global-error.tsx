'use client'

interface GlobalErrorProps {
  error: Error & { digest?: string }
  reset: () => void
}

export default function GlobalError({ error, reset }: GlobalErrorProps) {
  return (
    <html lang="pt-BR">
      <body>
        <div
          style={{
            display: 'flex',
            minHeight: '100vh',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '1rem',
            backgroundColor: '#0a0a0a',
            color: '#fafafa',
            fontFamily: 'system-ui, -apple-system, sans-serif',
          }}
        >
          <div
            style={{
              width: '100%',
              maxWidth: '32rem',
              borderRadius: '0.5rem',
              border: '1px solid #7f1d1d',
              backgroundColor: '#171717',
              padding: '1.5rem',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div
                style={{
                  borderRadius: '9999px',
                  backgroundColor: 'rgba(220, 38, 38, 0.1)',
                  padding: '0.75rem',
                  color: '#dc2626',
                }}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="24"
                  height="24"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <circle cx="12" cy="12" r="10" />
                  <line x1="12" y1="8" x2="12" y2="12" />
                  <line x1="12" y1="16" x2="12.01" y2="16" />
                </svg>
              </div>
              <div>
                <h1 style={{ fontSize: '1.25rem', fontWeight: 'bold', margin: 0 }}>
                  Erro Crítico
                </h1>
                <p style={{ color: '#a3a3a3', marginTop: '0.25rem', fontSize: '0.875rem' }}>
                  Ocorreu um erro crítico no sistema.
                </p>
              </div>
            </div>

            <div
              style={{
                marginTop: '1rem',
                padding: '0.75rem',
                borderRadius: '0.375rem',
                backgroundColor: 'rgba(220, 38, 38, 0.05)',
                border: '1px solid rgba(220, 38, 38, 0.2)',
              }}
            >
              <p style={{ fontFamily: 'monospace', fontSize: '0.875rem', margin: 0 }}>
                {error.message || 'Um erro inesperado ocorreu'}
              </p>
              {error.digest && (
                <p
                  style={{
                    fontFamily: 'monospace',
                    fontSize: '0.75rem',
                    color: '#a3a3a3',
                    marginTop: '0.5rem',
                  }}
                >
                  Digest: {error.digest}
                </p>
              )}
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.5rem' }}>
              <button
                onClick={reset}
                style={{
                  flex: 1,
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  borderRadius: '0.375rem',
                  backgroundColor: '#fafafa',
                  color: '#0a0a0a',
                  padding: '0.5rem 1rem',
                  fontSize: '0.875rem',
                  fontWeight: 500,
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                Tentar Novamente
              </button>
              <a
                href="/"
                style={{
                  flex: 1,
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  borderRadius: '0.375rem',
                  backgroundColor: 'transparent',
                  color: '#fafafa',
                  padding: '0.5rem 1rem',
                  fontSize: '0.875rem',
                  fontWeight: 500,
                  border: '1px solid #404040',
                  textDecoration: 'none',
                  cursor: 'pointer',
                }}
              >
                Voltar ao Início
              </a>
            </div>
          </div>
        </div>
      </body>
    </html>
  )
}
