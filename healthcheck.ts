/**
 * ===========================================================================
 * Health Check Script for Docker (Bun Native)
 * Manager DinastiAPI - Next.js 16 Application
 * ===========================================================================
 *
 * This script performs HTTP health checks on the Next.js application.
 * Used by Docker HEALTHCHECK directive to determine container health.
 *
 * Exit codes:
 * - 0: Application is healthy
 * - 1: Application is unhealthy
 */

const HOST = Bun.env.HOSTNAME || "localhost"
const PORT = Bun.env.PORT || "3000"
const TIMEOUT = 5000 // 5 seconds timeout
const PATH = "/" // Health check endpoint

async function performHealthCheck(): Promise<void> {
  const url = `http://${HOST}:${PORT}${PATH}`
  const startTime = Date.now()

  try {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT)

    const response = await fetch(url, {
      method: "GET",
      signal: controller.signal,
    })

    clearTimeout(timeoutId)

    const responseTime = Date.now() - startTime

    // Accept any 2xx or 3xx status codes (including redirects)
    const isHealthy = response.status >= 200 && response.status < 400

    if (isHealthy) {
      console.log(
        `[HEALTHCHECK] OK - Status: ${response.status}, Response time: ${responseTime}ms`
      )
      process.exit(0)
    } else {
      console.error(
        `[HEALTHCHECK] FAILED - Status: ${response.status}, Response time: ${responseTime}ms`
      )
      process.exit(1)
    }
  } catch (error) {
    const responseTime = Date.now() - startTime

    if (error instanceof Error) {
      if (error.name === "AbortError") {
        console.error(
          `[HEALTHCHECK] TIMEOUT - Request timed out after ${responseTime}ms`
        )
      } else {
        console.error(
          `[HEALTHCHECK] ERROR - ${error.message}, Response time: ${responseTime}ms`
        )
      }
    } else {
      console.error(
        `[HEALTHCHECK] ERROR - Unknown error, Response time: ${responseTime}ms`
      )
    }

    process.exit(1)
  }
}

// Run health check
performHealthCheck()
