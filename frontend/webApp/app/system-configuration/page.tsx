"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
import { useSystemConfigStore } from "@/lib/system-config-store"
import { ChevronLeft, ChevronRight } from "lucide-react"
import LayoutDiagram from "@/components/layout-diagram"
import Image from "next/image"

export default function SystemConfigurationPage() {
  const router = useRouter()
  const { config, updateConfig, submitConfig } = useSystemConfigStore()
  const [currentLayoutIndex, setCurrentLayoutIndex] = useState(0)
  const [availableLayouts, setAvailableLayouts] = useState<any[]>([])
  const [isClient, setIsClient] = useState(false)

  // Define all possible layouts
  const allLayouts = [
    {
      id: 1,
      name: "Solar + Battery + AC Load (Fully AC Off-Grid)",
      description:
        "Solar PV connected to a battery via a charge controller. The battery feeds an inverter, which powers the AC load. This simple off-grid setup is ideal for household-scale or micro-enterprise usage.",
      components: ["solar_pv", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 2,
      name: "Solar + Battery + Grid (Fully AC On-Grid)",
      description:
        "Solar PV charges the battery, which discharges through an inverter to supply the AC load. The grid supplements supply when solar and battery are insufficient and can charge the battery when needed.",
      components: ["solar_pv", "battery", "grid_connection"],
      requires_ac: true,
      requires_grid: true,
    },
    {
      id: 3,
      name: "Hybrid AC Mini-Grid (Solar + Diesel + Battery)",
      description:
        "Solar PV and diesel generator charge the battery. The inverter supplies the AC load. Diesel covers peak or nighttime demand, while solar provides the daytime base load.",
      components: ["solar_pv", "diesel_generator", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 4,
      name: "Fully Renewable AC Mini-Grid (Solar + Wind + Battery)",
      description:
        "Solar and wind turbine feed a battery storage system. The battery discharges through an inverter to power the AC load. Wind compensates for solar variability.",
      components: ["solar_pv", "wind_turbine", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 5,
      name: "DC Microgrid (Solar + Battery + DC Load)",
      description:
        "Solar PV charges the battery directly via a charge controller. The battery powers DC loads without needing an inverter, suitable for telecom towers, appliances, or small productive systems.",
      components: ["solar_pv", "battery"],
      requires_ac: false,
      requires_grid: false,
    },
    {
      id: 6,
      name: "Hydro + Battery + AC Load",
      description:
        "Mini-hydro generator powers the AC load and charges the battery. The battery supports load balancing and covers demand fluctuations or dry season variations.",
      components: ["mini_hydro", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 7,
      name: "Solar + Battery + DC + AC Loads",
      description:
        "Battery powers both DC and AC loads via direct feed and inverter. Useful in systems with mixed appliances.",
      components: ["solar_pv", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 8,
      name: "Wind + Battery + AC Load (Off-Grid)",
      description:
        "Wind turbine charges the battery, which powers the AC load through an inverter. Useful in areas with strong wind resources and limited solar potential.",
      components: ["wind_turbine", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 9,
      name: "Biogas + Battery + AC Load",
      description:
        "Dispatchable biogas generator feeds the inverter and charges the battery. Battery provides short-term balancing; inverter supplies AC loads.",
      components: ["biogas_generator", "battery"],
      requires_ac: true,
      requires_grid: false,
    },
    {
      id: 10,
      name: "On-Grid + Diesel Backup + AC Load",
      description:
        "Grid supplies AC loads under normal conditions. Diesel generator provides backup power through the inverter when the grid is unavailable.",
      components: ["grid_connection", "diesel_generator"],
      requires_ac: true,
      requires_grid: true,
    },
    {
      id: 11,
      name: "Solar + Biogas + Grid + Battery + AC Load",
      description:
        "Solar and biogas feed a battery that supplies AC load via an inverter. Grid acts as a backup or peak provider. Fully renewable primary generation, with grid support.",
      components: ["solar_pv", "biogas_generator", "grid_connection", "battery"],
      requires_ac: true,
      requires_grid: true,
    },
    {
      id: 12,
      name: "Solar + Diesel + AC Load (No battery)",
      description: "Solar PV covers daytime loads, diesel handles evening peaks. Simplified system without storage.",
      components: ["solar_pv", "diesel_generator"],
      requires_ac: true,
      requires_grid: false,
    },
  ]

  useEffect(() => {
    setIsClient(true)
  }, [])

  // Filter layouts based on selected components
  useEffect(() => {
    const enabledComponents = Object.entries(config.enabled_components)
      .filter(([_, enabled]) => enabled)
      .map(([component]) => component)

    const filteredLayouts = allLayouts.filter((layout) => {
      // Check if all required components for this layout are enabled
      const hasAllRequiredComponents = layout.components.every((component) => enabledComponents.includes(component))

      // Check if grid connection requirement matches
      const gridMatch =
        (layout.requires_grid && config.enabled_components.grid_connection) ||
        (!layout.requires_grid && !config.enabled_components.grid_connection)

      // Check if AC system requirement matches
      const acMatch = (layout.requires_ac && config.enabled_components.fully_ac) || !layout.requires_ac

      return hasAllRequiredComponents && gridMatch && acMatch
    })

    setAvailableLayouts(filteredLayouts.length > 0 ? filteredLayouts : allLayouts)

    // Reset current layout index if it's out of bounds
    if (currentLayoutIndex >= filteredLayouts.length && filteredLayouts.length > 0) {
      setCurrentLayoutIndex(0)
      updateConfig({ layout_id: filteredLayouts[0].id })
    }
  }, [config.enabled_components, currentLayoutIndex, updateConfig])

  const handleComponentToggle = (component: string, enabled: boolean) => {
    updateConfig({
      enabled_components: {
        ...config.enabled_components,
        [component]: enabled,
      },
    })
  }

  const handleSubmit = async () => {
    try {
      await submitConfig()
      // Navigate to technology parameters page
      router.push("/technology-parameters")
    } catch (error) {
      console.error("Error submitting system configuration:", error)
    }
  }

  const nextLayout = () => {
    if (currentLayoutIndex < availableLayouts.length - 1) {
      const newIndex = currentLayoutIndex + 1
      setCurrentLayoutIndex(newIndex)
      updateConfig({ layout_id: availableLayouts[newIndex].id })
    }
  }

  const prevLayout = () => {
    if (currentLayoutIndex > 0) {
      const newIndex = currentLayoutIndex - 1
      setCurrentLayoutIndex(newIndex)
      updateConfig({ layout_id: availableLayouts[newIndex].id })
    }
  }

  if (!isClient) {
    return <div>Loading...</div>
  }

  const currentLayout = availableLayouts[currentLayoutIndex] || allLayouts[0]

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
            <h2 className="text-xl font-bold">System Configuration</h2>
            <span className="text-sm text-gray-600">Step 2 of 5</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div className="bg-black h-2 rounded-full" style={{ width: "40%" }}></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <p className="text-lg mb-8 max-w-4xl">
          Use the component toggles and design mode filters to define your system setup. Then choose from a set of
          realistic, validated layouts to configure how the selected elements are connected through AC and/or DC buses
          to meet your energy needs.
        </p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Left Column - Layout Carousel */}
          <div>
            <h3 className="text-lg font-semibold mb-4">
              Select from the available validated layouts below based on your chosen components and design filters.
            </h3>

            <div className="relative border rounded-lg p-4 h-80 flex items-center justify-center mb-4 bg-white">
              {/* Layout Diagram */}
              <LayoutDiagram layoutId={currentLayout.id} className="max-w-full max-h-full" />

              {/* Navigation Arrows */}
              <button
                onClick={prevLayout}
                disabled={currentLayoutIndex === 0}
                className="absolute left-2 top-1/2 transform -translate-y-1/2 bg-white rounded-full p-2 shadow-md disabled:opacity-50 hover:bg-gray-50"
              >
                <ChevronLeft className="w-6 h-6" />
              </button>
              <button
                onClick={nextLayout}
                disabled={currentLayoutIndex === availableLayouts.length - 1}
                className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-white rounded-full p-2 shadow-md disabled:opacity-50 hover:bg-gray-50"
              >
                <ChevronRight className="w-6 h-6" />
              </button>
            </div>

            {/* Layout Description */}
            <div className="border rounded-lg p-4 bg-gray-50">
              <h4 className="font-medium mb-2">{currentLayout.name}</h4>
              <p className="text-sm text-gray-600">{currentLayout.description}</p>
            </div>
          </div>

          {/* Right Column - Component Selection */}
          <div>
            <h3 className="text-lg font-semibold mb-4">
              Select the components to be included in the mini-grid layout.
            </h3>

            {/* Renewables Technologies */}
            <div className="mb-6">
              <h4 className="font-medium mb-3">Renewables Technologies</h4>
              <div className="grid grid-cols-3 gap-4">
                <div
                  className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                    config.enabled_components.solar_pv ? "bg-amber-50 border-amber-200" : "bg-white"
                  }`}
                  onClick={() => handleComponentToggle("solar_pv", !config.enabled_components.solar_pv)}
                >
                  <div className="text-3xl mb-2">☀️</div>
                  <span className="text-sm">Solar PV</span>
                </div>
                <div
                  className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                    config.enabled_components.mini_hydro ? "bg-blue-50 border-blue-200" : "bg-white"
                  }`}
                  onClick={() => handleComponentToggle("mini_hydro", !config.enabled_components.mini_hydro)}
                >
                  <div className="text-3xl mb-2">⚡</div>
                  <span className="text-sm">Mini-Hydro</span>
                </div>
                <div
                  className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                    config.enabled_components.wind_turbine ? "bg-blue-50 border-blue-200" : "bg-white"
                  }`}
                  onClick={() => handleComponentToggle("wind_turbine", !config.enabled_components.wind_turbine)}
                >
                  <div className="text-3xl mb-2">🌪️</div>
                  <span className="text-sm">Wind Turbine</span>
                </div>
              </div>
            </div>

            {/* Fuel Generators and Storage */}
            <div className="grid grid-cols-2 gap-6 mb-6">
              <div>
                <h4 className="font-medium mb-3">Fuel Generators</h4>
                <div className="grid grid-cols-2 gap-4">
                  <div
                    className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                      config.enabled_components.diesel_generator ? "bg-gray-50 border-gray-300" : "bg-white"
                    }`}
                    onClick={() =>
                      handleComponentToggle("diesel_generator", !config.enabled_components.diesel_generator)
                    }
                  >
                    <div className="text-3xl mb-2">🔧</div>
                    <span className="text-sm">Diesel</span>
                  </div>
                  <div
                    className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                      config.enabled_components.biogas_generator ? "bg-green-50 border-green-200" : "bg-white"
                    }`}
                    onClick={() =>
                      handleComponentToggle("biogas_generator", !config.enabled_components.biogas_generator)
                    }
                  >
                    <div className="text-3xl mb-2">🌱</div>
                    <span className="text-sm">Biomass</span>
                  </div>
                </div>
              </div>

              <div>
                <h4 className="font-medium mb-3">Storage</h4>
                <div
                  className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                    config.enabled_components.battery ? "bg-blue-50 border-blue-200" : "bg-white"
                  }`}
                  onClick={() => handleComponentToggle("battery", !config.enabled_components.battery)}
                >
                  <div className="text-3xl mb-2">🔋</div>
                  <span className="text-sm">Battery</span>
                </div>
              </div>
            </div>

            {/* System Toggles */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <Label htmlFor="grid-connection" className="cursor-pointer">
                  Main Grid Connection
                </Label>
                <Switch
                  id="grid-connection"
                  checked={config.enabled_components.grid_connection}
                  onCheckedChange={(checked) => handleComponentToggle("grid_connection", checked)}
                />
              </div>
              <div className="flex items-center justify-between">
                <Label htmlFor="fully-ac" className="cursor-pointer">
                  Fully AC System
                </Label>
                <Switch
                  id="fully-ac"
                  checked={config.enabled_components.fully_ac}
                  onCheckedChange={(checked) => handleComponentToggle("fully_ac", checked)}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Navigation Buttons */}
        <div className="flex justify-end mt-12 space-x-4">
          <Link href="/project-setup">
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
