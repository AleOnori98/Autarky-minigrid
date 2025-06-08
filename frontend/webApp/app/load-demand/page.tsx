"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
import { Upload } from "lucide-react"
import Image from "next/image"
export default function LoadDemandPage() {
  const router = useRouter()
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [loadData, setLoadData] = useState<any>(null)
  const [visibleSeasons, setVisibleSeasons] = useState<string[]>([])
  const [rampEnabled, setRampEnabled] = useState(false)
  const [isClient, setIsClient] = useState(false)

  useEffect(() => {
    setIsClient(true)

    // Initialize with sample data for testing
    const sampleData = {
      timestep: Array.from({ length: 24 }, (_, i) => i),
      winter: [
        4.5, 4.2, 4.0, 3.8, 4.1, 5.2, 7.8, 9.5, 8.7, 7.9, 8.2, 9.1, 10.2, 11.5, 12.8, 14.2, 16.5, 18.9, 19.2, 17.8,
        15.4, 12.1, 8.7, 6.2,
      ],
      summer: [
        3.8, 3.5, 3.2, 3.0, 3.4, 4.8, 6.9, 8.2, 9.8, 11.2, 13.5, 15.8, 17.2, 18.9, 20.1, 19.8, 18.5, 16.9, 14.7, 12.3,
        9.8, 7.5, 5.9, 4.7,
      ],
    }

    setLoadData(sampleData)
    setVisibleSeasons(["winter", "summer"])
  }, [])

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file && file.type === "text/csv") {
      const reader = new FileReader()
      reader.onload = (e) => {
        const csv = e.target?.result as string
        parseCSV(csv)
      }
      reader.readAsText(file)
    }
  }

  const parseCSV = (csv: string) => {
    const lines = csv.split("\n").filter((line) => line.trim())
    const headers = lines[0].split(",").map((h) => h.trim())

    // For now, use sample data - in production, parse the actual CSV
    const sampleData = {
      timestep: Array.from({ length: 24 }, (_, i) => i),
      winter: [
        4.5, 4.2, 4.0, 3.8, 4.1, 5.2, 7.8, 9.5, 8.7, 7.9, 8.2, 9.1, 10.2, 11.5, 12.8, 14.2, 16.5, 18.9, 19.2, 17.8,
        15.4, 12.1, 8.7, 6.2,
      ],
      summer: [
        3.8, 3.5, 3.2, 3.0, 3.4, 4.8, 6.9, 8.2, 9.8, 11.2, 13.5, 15.8, 17.2, 18.9, 20.1, 19.8, 18.5, 16.9, 14.7, 12.3,
        9.8, 7.5, 5.9, 4.7,
      ],
    }

    setLoadData(sampleData)
    setVisibleSeasons(["winter", "summer"])
  }

  const handleSeasonToggle = (season: string, checked: boolean) => {
    if (checked) {
      setVisibleSeasons([...visibleSeasons, season])
    } else {
      setVisibleSeasons(visibleSeasons.filter((s) => s !== season))
    }
  }

  const handleSubmit = async () => {
    // Comment out validation for testing - uncomment for production
    // if (!loadData) {
    //   alert("Please upload a load demand file first")
    //   return
    // }

    try {
      const response = await fetch("/api/load-demand", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          project_id: "abc123",
          load_profile: loadData || {
            timestep: Array.from({ length: 24 }, (_, i) => i),
            default: Array.from({ length: 24 }, (_, i) => 5 + Math.random() * 10),
          },
        }),
      })

      if (response.ok) {
        router.push("/renewable-potential")
      }
    } catch (error) {
      console.error("Error submitting load demand:", error)
    }
  }

  if (!isClient) {
    return <div>Loading...</div>
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-[#FABC5F] px-6 py-4">
        <div className="flex items-center justify-between max-w-7xl mx-auto">
          <div className="flex items-center space-x-2">
            <div className="">
              <Image
                src="/Asset2.svg"
                alt="Autarky Logo"
                width={40}
                height={40}
                className="h-10 w-10 "
              />
            </div>
            <span className="text-xl font-bold text-black">Autarky</span>
          </div>
          <nav className="flex space-x-8">
            <Link href="#" className="text-black hover:text-gray-700">
              Who we are
            </Link>
            <Link href="#" className="text-black hover:text-gray-700">
              Contact us
            </Link>
            <Link href="#" className="text-black hover:text-gray-700">
              Resources
            </Link>
          </nav>
        </div>
      </header>

      {/* Progress Bar */}
      <div className="bg-gray-100 px-6 py-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-xl font-bold">Load Demand</h2>
            <span className="text-sm text-gray-600">Step 4 of 5</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div className="bg-black h-2 rounded-full" style={{ width: "80%" }}></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <p className="text-lg mb-8 max-w-4xl">
          Welcome to the Load Demand page, here you can upload time-series data for each consumption profile or generate
          synthetic data using RAMP. Visualize and review your inputs to ensure realistic and site-specific demand
          modeling.
        </p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Left Column - Upload Section */}
          <div>
            <h3 className="text-lg font-semibold mb-4">
              Upload time-series data for each defined load profile, or generate demand profiles using the integrated
              RAMP simulation tool.
            </h3>

            <div className="border rounded-lg p-6 space-y-6">
              <div>
                <h4 className="text-lg font-medium mb-4">Aggregated Load Demand</h4>

                <div className="space-y-4">
                  <div>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept=".csv"
                      onChange={handleFileUpload}
                      className="hidden"
                    />
                    <Button
                      onClick={() => fileInputRef.current?.click()}
                      variant="outline"
                      className="w-full flex items-center justify-center space-x-2"
                    >
                      <Upload className="w-4 h-4" />
                      <span>Upload CSV file</span>
                    </Button>
                  </div>

                  <div className="flex items-center space-x-2">
                    <Switch id="ramp-simulation" checked={rampEnabled} onCheckedChange={setRampEnabled} disabled />
                    <Label htmlFor="ramp-simulation" className="text-gray-400">
                      Simulate with RAMP (Coming Soon)
                    </Label>
                  </div>

                  <div>
                    <Button variant="outline" className="w-full flex items-center justify-center space-x-2" disabled>
                      <Upload className="w-4 h-4" />
                      <span>Upload RAMP Input file (Coming Soon)</span>
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column - Visualization */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Use the filters to visualize different seasons.</h3>
              <div className="text-sm text-gray-600">Time Series Data</div>
            </div>

            {loadData && (
              <div className="mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium">Use the filters to visualize different seasons.</span>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs text-gray-500">Filters:</span>
                    <div className="flex space-x-1">
                      {Object.keys(loadData)
                        .filter((key) => key !== "timestep")
                        .map((season) => (
                          <button
                            key={season}
                            onClick={() => handleSeasonToggle(season, !visibleSeasons.includes(season))}
                            className={`px-3 py-1 text-xs rounded-full border ${
                              visibleSeasons.includes(season)
                                ? season === "summer"
                                  ? "bg-amber-100 border-amber-300 text-amber-800"
                                  : "bg-blue-100 border-blue-300 text-blue-800"
                                : "bg-gray-100 border-gray-300 text-gray-600"
                            }`}
                          >
                            {season.charAt(0).toUpperCase() + season.slice(1)}
                          </button>
                        ))}
                    </div>
                  </div>
                </div>
              </div>
            )}

            <div className="border rounded-lg p-4 h-80 bg-white flex items-center justify-center">
              {loadData ? (
                <div className="w-full h-full relative">
                  {/* Chart container with white background */}
                  <div className="relative w-full h-full bg-white border rounded">
                    {/* Grid lines */}
                    <svg className="absolute inset-0 w-full h-full">
                      {/* Horizontal grid lines */}
                      {Array.from({ length: 6 }).map((_, i) => (
                        <line
                          key={`h-${i}`}
                          x1="0"
                          y1={`${(i / 5) * 100}%`}
                          x2="100%"
                          y2={`${(i / 5) * 100}%`}
                          stroke="#e5e7eb"
                          strokeWidth="1"
                        />
                      ))}
                      {/* Vertical grid lines */}
                      {Array.from({ length: 7 }).map((_, i) => (
                        <line
                          key={`v-${i}`}
                          x1={`${(i / 6) * 100}%`}
                          y1="0"
                          x2={`${(i / 6) * 100}%`}
                          y2="100%"
                          stroke="#e5e7eb"
                          strokeWidth="1"
                        />
                      ))}
                    </svg>

                    {/* Chart lines */}
                    {visibleSeasons.includes("winter") && (
                      <svg className="absolute inset-0 w-full h-full">
                        <polyline
                          fill="none"
                          stroke="#3b82f6"
                          strokeWidth="3"
                          points={loadData.winter
                            .map((value: number, index: number) => {
                              const x = (index / 23) * 100
                              const y = 100 - (value / 25) * 80 // Use 80% of height for better visibility
                              return `${x},${y}`
                            })
                            .join(" ")}
                          vectorEffect="non-scaling-stroke"
                        />
                      </svg>
                    )}

                    {visibleSeasons.includes("summer") && (
                      <svg className="absolute inset-0 w-full h-full">
                        <polyline
                          fill="none"
                          stroke="#f59e0b"
                          strokeWidth="3"
                          points={loadData.summer
                            .map((value: number, index: number) => {
                              const x = (index / 23) * 100
                              const y = 100 - (value / 25) * 80 // Use 80% of height for better visibility
                              return `${x},${y}`
                            })
                            .join(" ")}
                          vectorEffect="non-scaling-stroke"
                        />
                      </svg>
                    )}

                    {/* Y-axis labels */}
                    <div className="absolute left-0 top-0 bottom-0 w-8 flex flex-col justify-between text-xs text-gray-600 py-2">
                      <span>25</span>
                      <span>20</span>
                      <span>15</span>
                      <span>10</span>
                      <span>5</span>
                      <span>0</span>
                    </div>

                    {/* X-axis labels */}
                    <div className="absolute bottom-0 left-8 right-0 h-6 flex justify-between text-xs text-gray-600 items-center">
                      <span>0</span>
                      <span>4</span>
                      <span>8</span>
                      <span>12</span>
                      <span>16</span>
                      <span>20</span>
                      <span>24</span>
                    </div>

                    {/* Legend */}
                    <div className="absolute top-4 right-4 bg-white p-3 rounded shadow border">
                      <div className="text-xs">
                        <div className="text-gray-600 mb-2 font-medium">Season</div>
                        {visibleSeasons.includes("winter") && (
                          <div className="flex items-center space-x-2 mb-1">
                            <div className="w-4 h-0.5 bg-blue-500"></div>
                            <span>Winter</span>
                          </div>
                        )}
                        {visibleSeasons.includes("summer") && (
                          <div className="flex items-center space-x-2">
                            <div className="w-4 h-0.5 bg-amber-500"></div>
                            <span>Summer</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Axis titles */}
                    <div className="absolute bottom-0 left-0 right-0 text-xs text-gray-600 text-center pb-1">
                      Hours (0-24)
                    </div>
                    <div className="absolute left-0 top-0 bottom-0 text-xs text-gray-600 transform -rotate-90 flex items-center justify-center w-4">
                      Load (kW)
                    </div>
                  </div>
                </div>
              ) : (
                <div className="text-center text-gray-500">
                  <p>Upload a CSV file to visualize load demand data</p>
                  <p className="text-sm mt-2">(Sample data will load automatically for testing)</p>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Navigation Buttons - Fixed positioning */}
        <div className="flex justify-between mt-12">
          <Link href="/technology-parameters">
            <Button variant="outline" className="px-8 py-2">
              Back
            </Button>
          </Link>
          <Button onClick={handleSubmit} className="bg-black hover:bg-gray-800 text-white px-8 py-2">
            Next
          </Button>
        </div>
      </main>
    </div>
  )
}
