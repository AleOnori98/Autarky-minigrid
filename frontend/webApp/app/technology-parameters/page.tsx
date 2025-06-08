"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip"
import { useTechParamsStore } from "@/lib/tech-params-store"
import { useSystemConfigStore } from "@/lib/system-config-store"
import { Info } from "lucide-react"
import Image from "next/image"

export default function TechnologyParametersPage() {
  const router = useRouter()
  const { params, updateEconomicSettings, updateComponentParams, selectComponent, submitParams } = useTechParamsStore()
  const { config } = useSystemConfigStore()
  const [isClient, setIsClient] = useState(false)

  useEffect(() => {
    setIsClient(true)
  }, [])

  const handleSubmit = async () => {
    try {
      await submitParams()
      // Navigate to load demand page
      router.push("/load-demand")
    } catch (error) {
      console.error("Error submitting technology parameters:", error)
    }
  }

  // Get the enabled components from the system configuration
  const enabledComponents = Object.entries(config.enabled_components)
    .filter(([_, enabled]) => enabled)
    .map(([component]) => component)

  // Render parameter fields based on the selected component
  const renderParameterFields = () => {
    const selectedComponent = params.selectedComponent

    if (!selectedComponent || !params.technology_parameters[selectedComponent]) {
      return (
        <div className="p-6 text-center text-gray-500">
          <p>Select a component from the system layout to view and edit its parameters.</p>
        </div>
      )
    }

    switch (selectedComponent) {
      case "solar_pv":
        return (
          <div className="space-y-6">
            <h3 className="text-xl font-semibold">Solar PV</h3>
            <div className="space-y-4">
              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="solar-investment-cost">Investment Cost:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Cost per kW of installed capacity</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="solar-investment-cost"
                    type="number"
                    value={params.technology_parameters.solar_pv?.investment_cost}
                    onChange={(e) =>
                      updateComponentParams("solar_pv", {
                        investment_cost: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">{params.project_economic_settings.currency}/kW</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="solar-operation-cost">Operation Cost:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Annual operation and maintenance cost as percentage of investment cost</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="solar-operation-cost"
                    type="number"
                    value={params.technology_parameters.solar_pv?.operation_cost}
                    onChange={(e) =>
                      updateComponentParams("solar_pv", {
                        operation_cost: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">% of CAPEX/year</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="solar-subsidy">Subsidy:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Percentage of investment cost covered by subsidies</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="solar-subsidy"
                    type="number"
                    value={params.technology_parameters.solar_pv?.subsidy}
                    onChange={(e) =>
                      updateComponentParams("solar_pv", {
                        subsidy: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">% of CAPEX</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="solar-lifetime">Lifetime:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Expected operational lifetime of the solar PV system</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="solar-lifetime"
                    type="number"
                    value={params.technology_parameters.solar_pv?.lifetime}
                    onChange={(e) =>
                      updateComponentParams("solar_pv", {
                        lifetime: Number.parseInt(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">years</span>
                </div>
              </div>
            </div>
          </div>
        )

      case "battery":
        return (
          <div className="space-y-6">
            <h3 className="text-xl font-semibold">Battery</h3>
            <div className="space-y-4">
              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-nominal-capacity">Nominal Capacity:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Total energy storage capacity of the battery</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-nominal-capacity"
                    type="number"
                    value={params.technology_parameters.battery?.nominal_capacity}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        nominal_capacity: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">kWh</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-investment-cost">Investment Cost:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Cost per kWh of battery capacity</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-investment-cost"
                    type="number"
                    value={params.technology_parameters.battery?.investment_cost}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        investment_cost: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">{params.project_economic_settings.currency}/kWh</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-operation-cost">Operation Cost:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Annual operation and maintenance cost as percentage of investment cost</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-operation-cost"
                    type="number"
                    value={params.technology_parameters.battery?.operation_cost}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        operation_cost: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">% of CAPEX/year</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-lifetime">Lifetime:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Expected operational lifetime of the battery</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-lifetime"
                    type="number"
                    value={params.technology_parameters.battery?.lifetime}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        lifetime: Number.parseInt(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">years</span>
                </div>
              </div>

              <h4 className="font-medium pt-2">Operation</h4>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-charging-efficiency">Charging Efficiency:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Efficiency of the battery during charging</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-charging-efficiency"
                    type="number"
                    value={params.technology_parameters.battery?.charging_efficiency}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        charging_efficiency: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">%</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-discharging-efficiency">Discharging Efficiency:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Efficiency of the battery during discharging</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-discharging-efficiency"
                    type="number"
                    value={params.technology_parameters.battery?.discharging_efficiency}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        discharging_efficiency: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">%</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-soc-min">Minimum SOC:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Minimum state of charge allowed</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-soc-min"
                    type="number"
                    value={params.technology_parameters.battery?.soc_min}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        soc_min: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">%</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="battery-soc-max">Maximum SOC:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Maximum state of charge allowed</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="battery-soc-max"
                    type="number"
                    value={params.technology_parameters.battery?.soc_max}
                    onChange={(e) =>
                      updateComponentParams("battery", {
                        soc_max: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">%</span>
                </div>
              </div>
            </div>
          </div>
        )

      case "diesel_generator":
        return (
          <div className="space-y-6">
            <h3 className="text-xl font-semibold">Diesel Generator</h3>
            <div className="space-y-4">
              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="diesel-nominal-capacity">Nominal Capacity:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Maximum power output of the generator</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="diesel-nominal-capacity"
                    type="number"
                    value={params.technology_parameters.diesel_generator?.nominal_capacity}
                    onChange={(e) =>
                      updateComponentParams("diesel_generator", {
                        nominal_capacity: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">kW</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="diesel-nominal-efficiency">Nominal Efficiency:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Efficiency at rated power</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="diesel-nominal-efficiency"
                    type="number"
                    value={params.technology_parameters.diesel_generator?.nominal_efficiency}
                    onChange={(e) =>
                      updateComponentParams("diesel_generator", {
                        nominal_efficiency: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">%</span>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="diesel-partial-load"
                  checked={params.technology_parameters.diesel_generator?.partial_load_enabled}
                  onCheckedChange={(checked) =>
                    updateComponentParams("diesel_generator", {
                      partial_load_enabled: !!checked,
                    })
                  }
                />
                <Label htmlFor="diesel-partial-load">Enable Partial Load Efficiency</Label>
              </div>

              {params.technology_parameters.diesel_generator?.partial_load_enabled && (
                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="diesel-efficiency-samples">Number of Efficiency Samples:</Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Number of points on the efficiency curve</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Input
                    id="diesel-efficiency-samples"
                    type="number"
                    value={params.technology_parameters.diesel_generator?.efficiency_samples}
                    onChange={(e) =>
                      updateComponentParams("diesel_generator", {
                        efficiency_samples: Number.parseInt(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                </div>
              )}

              <h4 className="font-medium pt-2">Economics</h4>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="diesel-investment-cost">Investment Cost:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Cost per kW of installed capacity</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="diesel-investment-cost"
                    type="number"
                    value={params.technology_parameters.diesel_generator?.investment_cost}
                    onChange={(e) =>
                      updateComponentParams("diesel_generator", {
                        investment_cost: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">{params.project_economic_settings.currency}/kW</span>
                </div>
              </div>

              <h4 className="font-medium pt-2">Fuel</h4>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="diesel-fuel-type">Fuel Type:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Type of fuel used by the generator</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <Input
                  id="diesel-fuel-type"
                  value={params.technology_parameters.diesel_generator?.fuel_type}
                  onChange={(e) =>
                    updateComponentParams("diesel_generator", {
                      fuel_type: e.target.value,
                    })
                  }
                  className="mt-1"
                />
              </div>

              <div>
                <div className="flex items-center justify-between">
                  <Label htmlFor="diesel-fuel-cost">Fuel Cost:</Label>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>Cost per liter of fuel</p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
                <div className="flex items-center">
                  <Input
                    id="diesel-fuel-cost"
                    type="number"
                    value={params.technology_parameters.diesel_generator?.fuel_cost}
                    onChange={(e) =>
                      updateComponentParams("diesel_generator", {
                        fuel_cost: Number.parseFloat(e.target.value) || 0,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="ml-2">{params.project_economic_settings.currency}/liter</span>
                </div>
              </div>

              <div className="flex items-center space-x-2">
                <Checkbox
                  id="diesel-fuel-limit"
                  checked={params.technology_parameters.diesel_generator?.fuel_limit_enabled}
                  onCheckedChange={(checked) =>
                    updateComponentParams("diesel_generator", {
                      fuel_limit_enabled: !!checked,
                    })
                  }
                />
                <Label htmlFor="diesel-fuel-limit">Fuel Consumption Limit</Label>
              </div>

              {params.technology_parameters.diesel_generator?.fuel_limit_enabled && (
                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="diesel-fuel-limit-max">Max Annual Fuel Consumption:</Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Maximum amount of fuel that can be consumed per year</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <div className="flex items-center">
                    <Input
                      id="diesel-fuel-limit-max"
                      type="number"
                      value={params.technology_parameters.diesel_generator?.fuel_limit_max}
                      onChange={(e) =>
                        updateComponentParams("diesel_generator", {
                          fuel_limit_max: Number.parseFloat(e.target.value) || 0,
                        })
                      }
                      className="mt-1"
                    />
                    <span className="ml-2">liters</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        )

      default:
        return (
          <div className="p-6 text-center text-gray-500">
            <p>Parameters for this component are not available.</p>
          </div>
        )
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
                className="h-10 w-10 rounded-full"
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
            <h2 className="text-xl font-bold">Technology Parameters</h2>
            <span className="text-sm text-gray-600">Step 3 of 5</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div className="bg-black h-2 rounded-full" style={{ width: "60%" }}></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <p className="text-lg mb-8 max-w-4xl">
          Welcome to the Techno-Economic Parameters page, here you can define the technical and financial
          characteristics of your energy system. Click on each component in the system layout to view and edit
          parameters such as efficiency, capacity, investment cost, operational cost, and lifetime.
        </p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Left Column - Interactive System Layout */}
          <div>
            <h3 className="text-lg font-semibold mb-4">
              Click on each component in the system layout to display and edit its technical and financial parameters on
              the right panel.
            </h3>

            <div className="border rounded-lg p-6 bg-white h-96 relative">
              {/* Interactive Layout */}
              {/* <div className="w-full h-full">
                <LayoutDiagram layoutId={config.layout_id} className="w-full h-full" />

                {/* Clickable Overlays */}
              {/* {enabledComponents.includes("solar_pv") && (
                  <div
                    className={`absolute left-[60px] top-[70px] w-16 h-16 rounded-lg cursor-pointer ${
                      params.selectedComponent === "solar_pv" ? "bg-yellow-200 bg-opacity-50" : "hover:bg-yellow-100"
                    }`}
                    onClick={() => selectComponent("solar_pv")}
                  ></div>
                )}

                {enabledComponents.includes("battery") && (
                  <div
                    className={`absolute left-[200px] top-[70px] w-16 h-16 rounded-lg cursor-pointer ${
                      params.selectedComponent === "battery" ? "bg-green-200 bg-opacity-50" : "hover:bg-green-100"
                    }`}
                    onClick={() => selectComponent("battery")}
                  ></div>
                )}

                {enabledComponents.includes("diesel_generator") && (
                  <div
                    className={`absolute left-[60px] top-[150px] w-16 h-16 rounded-lg cursor-pointer ${
                      params.selectedComponent === "diesel_generator"
                        ? "bg-brown-200 bg-opacity-50"
                        : "hover:bg-brown-100"
                    }`}
                    onClick={() => selectComponent("diesel_generator")}
                  ></div>
                )}
              </div> */}
              {/* Left Column - Interactive Component Selection */}
              <div>
                <h3 className="text-lg font-semibold mb-4">
                  Click on each component to display and edit its technical and financial parameters on the right panel.
                </h3>

                <div className="space-y-4">
                  {/* Renewables Technologies */}
                  <div>
                    <h4 className="font-medium mb-3">Renewables Technologies</h4>
                    <div className="grid grid-cols-2 gap-4">
                      {enabledComponents.includes("solar_pv") && (
                        <div
                          className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                            params.selectedComponent === "solar_pv"
                              ? "bg-amber-50 border-amber-200"
                              : "bg-white hover:bg-gray-50"
                          }`}
                          onClick={() => selectComponent("solar_pv")}
                        >
                          <div className="text-4xl mb-2">☀️</div>
                          <span className="text-sm font-medium">Solar PV</span>
                        </div>
                      )}

                      {enabledComponents.includes("wind_turbine") && (
                        <div
                          className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                            params.selectedComponent === "wind_turbine"
                              ? "bg-blue-50 border-blue-200"
                              : "bg-white hover:bg-gray-50"
                          }`}
                          onClick={() => selectComponent("wind_turbine")}
                        >
                          <div className="text-4xl mb-2">🌪️</div>
                          <span className="text-sm font-medium">Wind Turbine</span>
                        </div>
                      )}

                      {enabledComponents.includes("mini_hydro") && (
                        <div
                          className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                            params.selectedComponent === "mini_hydro"
                              ? "bg-blue-50 border-blue-200"
                              : "bg-white hover:bg-gray-50"
                          }`}
                          onClick={() => selectComponent("mini_hydro")}
                        >
                          <div className="text-4xl mb-2">⚡</div>
                          <span className="text-sm font-medium">Mini-Hydro</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Storage */}
                  <div>
                    <h4 className="font-medium mb-3">Storage</h4>
                    <div className="grid grid-cols-2 gap-4">
                      {enabledComponents.includes("battery") && (
                        <div
                          className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                            params.selectedComponent === "battery"
                              ? "bg-green-50 border-green-200"
                              : "bg-white hover:bg-gray-50"
                          }`}
                          onClick={() => selectComponent("battery")}
                        >
                          <div className="text-4xl mb-2">🔋</div>
                          <span className="text-sm font-medium">Battery</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Fuel Generators */}
                  <div>
                    <h4 className="font-medium mb-3">Fuel Generators</h4>
                    <div className="grid grid-cols-2 gap-4">
                      {enabledComponents.includes("diesel_generator") && (
                        <div
                          className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                            params.selectedComponent === "diesel_generator"
                              ? "bg-gray-50 border-gray-300"
                              : "bg-white hover:bg-gray-50"
                          }`}
                          onClick={() => selectComponent("diesel_generator")}
                        >
                          <div className="text-4xl mb-2">🔧</div>
                          <span className="text-sm font-medium">Diesel Generator</span>
                        </div>
                      )}

                      {enabledComponents.includes("biogas_generator") && (
                        <div
                          className={`border rounded-lg p-4 flex flex-col items-center justify-center cursor-pointer ${
                            params.selectedComponent === "biogas_generator"
                              ? "bg-green-50 border-green-200"
                              : "bg-white hover:bg-gray-50"
                          }`}
                          onClick={() => selectComponent("biogas_generator")}
                        >
                          <div className="text-4xl mb-2">🌱</div>
                          <span className="text-sm font-medium">Biogas Generator</span>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column - Parameter Panel */}
          <div>
            {/* Project Economic Settings */}
            <div className="mb-8">
              <h3 className="text-lg font-semibold mb-4">Project Economic Settings</h3>
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="discount-rate">Discount Rate:</Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Annual discount rate used for economic calculations</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <div className="flex items-center">
                    <Input
                      id="discount-rate"
                      type="number"
                      value={params.project_economic_settings.discount_rate}
                      onChange={(e) =>
                        updateEconomicSettings({
                          discount_rate: Number.parseFloat(e.target.value) || 0,
                        })
                      }
                      className="mt-1"
                    />
                    <span className="ml-2">%</span>
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="currency">Currency:</Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Currency used for all cost calculations</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Input
                    id="currency"
                    value={params.project_economic_settings.currency}
                    onChange={(e) =>
                      updateEconomicSettings({
                        currency: e.target.value,
                      })
                    }
                    className="mt-1"
                  />
                </div>
              </div>
            </div>

            {/* Component Parameters */}
            <div className="border rounded-lg p-6 bg-gray-50 min-h-[400px] max-h-[600px] overflow-y-auto">
              {renderParameterFields()}
            </div>
          </div>
        </div>

        {/* Navigation Buttons */}
        <div className="flex justify-end mt-12 space-x-4">
          <Link href="/system-configuration">
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
