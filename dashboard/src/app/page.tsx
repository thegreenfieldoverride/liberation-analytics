'use client'

import { useState, useEffect } from 'react'
import { Activity, Database, Key, Server, RefreshCw } from 'lucide-react'

interface HealthStatus {
  status: string
  database: string
  service: string
  timestamp: string
}

interface ServiceStats {
  containers: number
  uptime: string
  memory: string
}

export default function Dashboard() {
  const [health, setHealth] = useState<HealthStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchHealth = async () => {
    try {
      const response = await fetch('/api/health')
      if (!response.ok) throw new Error('Failed to fetch health')
      const data = await response.json()
      setHealth(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchHealth()
    const interval = setInterval(fetchHealth, 30000) // Refresh every 30s
    return () => clearInterval(interval)
  }, [])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ok':
      case 'connected':
        return 'text-green-600 bg-green-100'
      case 'error':
      case 'disconnected':
        return 'text-red-600 bg-red-100'
      default:
        return 'text-yellow-600 bg-yellow-100'
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="px-4 py-6 sm:px-0">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Liberation Analytics Dashboard
              </h1>
              <p className="mt-2 text-sm text-gray-600">
                Manage analytics services, API tokens, and monitor system health
              </p>
            </div>
            <button
              onClick={fetchHealth}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-liberation-600 hover:bg-liberation-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-liberation-500"
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Refresh
            </button>
          </div>
        </div>

        {/* Status Cards */}
        <div className="px-4 sm:px-0">
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {/* Service Status */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Server className="h-6 w-6 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Service Status
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {loading ? '...' : health?.status || 'Unknown'}
                        </div>
                        {health && (
                          <div className={`ml-2 px-2 py-1 text-xs rounded-full ${getStatusColor(health.status)}`}>
                            {health.status}
                          </div>
                        )}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            {/* Database Status */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Database className="h-6 w-6 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Database
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {loading ? '...' : health?.database || 'Unknown'}
                        </div>
                        {health && (
                          <div className={`ml-2 px-2 py-1 text-xs rounded-full ${getStatusColor(health.database)}`}>
                            {health.database}
                          </div>
                        )}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            {/* API Tokens */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Key className="h-6 w-6 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        API Tokens
                      </dt>
                      <dd className="text-2xl font-semibold text-gray-900">
                        0
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            {/* Recent Events */}
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <Activity className="h-6 w-6 text-gray-400" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        Events (24h)
                      </dt>
                      <dd className="text-2xl font-semibold text-gray-900">
                        0
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Error Display */}
        {error && (
          <div className="mt-6 px-4 sm:px-0">
            <div className="rounded-md bg-red-50 p-4">
              <div className="text-sm text-red-700">
                Error: {error}
              </div>
            </div>
          </div>
        )}

        {/* Quick Actions */}
        <div className="mt-8 px-4 sm:px-0">
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                Quick Actions
              </h3>
              <div className="mt-5">
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
                  <button className="inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-liberation-500">
                    <Key className="w-4 h-4 mr-2" />
                    Manage Tokens
                  </button>
                  <button className="inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-liberation-500">
                    <Activity className="w-4 h-4 mr-2" />
                    View Insights
                  </button>
                  <button className="inline-flex items-center justify-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-liberation-500">
                    <Server className="w-4 h-4 mr-2" />
                    Service Logs
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Health Details */}
        {health && (
          <div className="mt-8 px-4 sm:px-0">
            <div className="bg-white shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <h3 className="text-lg leading-6 font-medium text-gray-900">
                  System Details
                </h3>
                <div className="mt-5">
                  <dl className="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Service</dt>
                      <dd className="mt-1 text-sm text-gray-900">{health.service}</dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Last Check</dt>
                      <dd className="mt-1 text-sm text-gray-900">
                        {new Date(health.timestamp).toLocaleString()}
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">API Endpoint</dt>
                      <dd className="mt-1 text-sm text-gray-900">
                        https://analytics.greenfieldoverride.com
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Environment</dt>
                      <dd className="mt-1 text-sm text-gray-900">Production</dd>
                    </div>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}