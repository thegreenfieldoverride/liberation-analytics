import { NextRequest, NextResponse } from 'next/server'

export async function GET() {
  try {
    // In production, this should point to the analytics service
    // For now, we'll proxy to the analytics API
    const analyticsUrl = process.env.ANALYTICS_API_URL || 'http://liberation-analytics:8080'
    
    const response = await fetch(`${analyticsUrl}/api/health`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error(`Analytics API returned ${response.status}`)
    }

    const data = await response.json()
    
    return NextResponse.json(data)
  } catch (error) {
    console.error('Health check failed:', error)
    
    return NextResponse.json(
      { 
        status: 'error',
        service: 'liberation-analytics-dashboard',
        database: 'unknown',
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 503 }
    )
  }
}