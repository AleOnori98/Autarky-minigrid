"use client"

import type React from "react"

import { useState, useEffect, useRef } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { ChevronLeft, ChevronRight, Upload, Download } from "lucide-react"

export default function RenewablePotentialPage() {
  const router = useRouter()
  const [currentComponent, setCurrentComponent] = useState(0)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [isClient, setIsClient] = useState(false)

  const components = [
    {
      name: "Solar PV",
      icon: "☀️",
      description: "Upload CSV file with electricity production profile per unit of nominal capacity",
      apiDescription: "Download irradiance data from PVGIS API and simulate PV electricity production",
      apiName: "PVGIS",
    },
    {
      name: "Wind Turbine",
      icon: "🌪️",
      description: "Upload CSV file with electricity production profile per unit of nominal capacity",
      apiDescription: "Download wind speed data from PVGIS API and simulate wind electricity production",
      apiName: "PVGIS",
    },
    {
      name: "Mini-Hydro",
      icon: "⚡",
      description: "Upload CSV file with water flow rate data for mini-hydro potential assessment",
      apiDescription: "Download hydrological data from external APIs",
      apiName: "Hydro API",
    },
  ]

  useEffect(() => {
    setIsClient(true)
  }, [])

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file && file.type === "text/csv") {
      console.log("File uploaded:", file.name)
      // Handle file processing here
    }
  }

  const handleAPIDownload = () => {
    console.log(`Downloading from ${components[currentComponent].apiName} API`)
    // Handle API download here
  }

  const nextComponent = () => {
    if (currentComponent < components.length - 1) {
      setCurrentComponent(currentComponent + 1)
    }
  }

  const prevComponent = () => {
    if (currentComponent > 0) {
      setCurrentComponent(currentComponent - 1)
    }
  }

  const handleSubmit = async () => {
    try {
      // Submit renewable potential data
      router.push("/model-uncertainties")
    } catch (error) {
      console.error("Error submitting renewable potential:", error)
    }
  }

  if (!isClient) {
    return <div>Loading...</div>
  }

  const current = components[currentComponent]

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-orange-400 px-6 py-4">
        <div className="flex items-center justify-between max-w-7xl mx-auto">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-orange-600 transform rotate-45"></div>
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
            <h2 className="text-xl font-bold">Renewables Potential</h2>
            <span className="text-sm text-gray-600">Step 5 of 5</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div className="bg-black h-2 rounded-full" style={{ width: "100%" }}></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <p className="text-lg mb-8 max-w-4xl">
          Welcome to the Renewable Potential page, here you can input site-specific renewable resource data by uploading
          CSV files or retrieving data directly from the PVGIS API for solar production and wind speed. Customize wind
          energy generation using power curves, and provide mini-hydro potential via uploaded flow rate data.
        </p>

        <div className="relative">
          {/* Component Carousel */}
          <div className="border rounded-lg p-8 min-h-[400px] flex items-center justify-between">
            {/* Navigation Arrow Left */}
            <button
              onClick={prevComponent}
              disabled={currentComponent === 0}
              className="absolute left-4 top-1/2 transform -translate-y-1/2 bg-white rounded-full p-2 shadow-md disabled:opacity-50 hover:bg-gray-50 z-10"
            >
              <ChevronLeft className="w-6 h-6" />
            </button>

            {/* Component Content */}
            <div className="flex-1 grid grid-cols-1 lg:grid-cols-2 gap-12 mx-16">
              {/* Left Side - Component Info and Actions */}
              <div className="space-y-6">
                <div className="text-center">
                  <div className="text-6xl mb-4">{current.icon}</div>
                  <h3 className="text-2xl font-bold mb-2">{current.name}</h3>
                </div>

                <div className="space-y-4">
                  <div>
                    <p className="text-gray-700 mb-4">{current.description}</p>
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

                  <div className="border-t pt-4">
                    <p className="text-gray-700 mb-4">{current.apiDescription}</p>
                    <Button
                      onClick={handleAPIDownload}
                      className="w-full flex items-center justify-center space-x-2 bg-blue-600 hover:bg-blue-700"
                    >
                      <Download className="w-4 h-4" />
                      <span>Download from {current.apiName}</span>
                    </Button>
                  </div>
                </div>
              </div>

              {/* Right Side - Visualization/Map */}
              <div className="flex items-center justify-center">
                <div className="w-full h-80 bg-gray-100 rounded-lg flex items-center justify-center">
                  {current.name === "Solar PV" && (
                    <div className="text-center">
                      <div className="w-64 h-48 bg-gradient-to-br from-yellow-200 via-orange-300 to-red-400 rounded-lg mb-4 flex items-center justify-center">
                        <span className="text-white font-bold">Global Solar Irradiance Map</span>
                      </div>
                      <div className="text-sm text-gray-600">
                        <div className="bg-white p-2 rounded border">
                          <div className="text-xs">Monthly capacity factor [%]</div>
                          <div className="grid grid-cols-6 gap-1 mt-1">
                            {["Jan", "Feb", "Mar", "Apr", "May", "Jun"].map((month) => (
                              <div key={month} className="text-xs">
                                {month}
                              </div>
                            ))}
                          </div>
                          <div className="text-xs mt-1">Solar irradiation data: PVGIS</div>
                        </div>
                      </div>
                    </div>
                  )}

                  {current.name === "Wind Turbine" && (
                    <div className="text-center">
                      <div className="w-64 h-48 bg-gradient-to-br from-blue-200 via-cyan-300 to-teal-400 rounded-lg mb-4 flex items-center justify-center">
                        <span className="text-white font-bold">Global Wind Speed Map</span>
                      </div>
                      <div className="text-sm text-gray-600">Wind speed data visualization</div>
                    </div>
                  )}

                  {current.name === "Mini-Hydro" && (
                    <div className="text-center">
                      <div className="w-64 h-48 bg-gradient-to-br from-blue-300 via-blue-400 to-blue-600 rounded-lg mb-4 flex items-center justify-center">
                        <span className="text-white font-bold">Hydrological Data Map</span>
                      </div>
                      <div className="text-sm text-gray-600">Water flow rate visualization</div>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Navigation Arrow Right */}
            <button
              onClick={nextComponent}
              disabled={currentComponent === components.length - 1}
              className="absolute right-4 top-1/2 transform -translate-y-1/2 bg-white rounded-full p-2 shadow-md disabled:opacity-50 hover:bg-gray-50 z-10"
            >
              <ChevronRight className="w-6 h-6" />
            </button>
          </div>

          {/* Component Indicators */}
          <div className="flex justify-center mt-6 space-x-2">
            {components.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentComponent(index)}
                className={`w-3 h-3 rounded-full ${index === currentComponent ? "bg-orange-400" : "bg-gray-300"}`}
              />
            ))}
          </div>
        </div>

        {/* Navigation Buttons */}
        <div className="flex justify-end mt-12 space-x-4">
          <Link href="/load-demand">
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
