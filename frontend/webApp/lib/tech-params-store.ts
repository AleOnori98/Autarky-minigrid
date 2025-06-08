import { create } from "zustand"

// Define types for each component's parameters
interface ProjectEconomicSettings {
  discount_rate: number
  currency: string
}

interface SolarPVParams {
  investment_cost: number
  operation_cost: number
  subsidy: number
  lifetime: number
}

interface WindTurbineParams {
  investment_cost: number
  operation_cost: number
  subsidy: number
  lifetime: number
}

interface BatteryParams {
  nominal_capacity: number
  investment_cost: number
  operation_cost: number
  lifetime: number
  charge_time: number
  discharge_time: number
  charging_efficiency: number
  discharging_efficiency: number
  soc_min: number
  soc_max: number
  soc_initial: number
}

interface FuelGeneratorParams {
  nominal_capacity: number
  nominal_efficiency: number
  partial_load_enabled: boolean
  efficiency_samples: number
  investment_cost: number
  operation_cost: number
  lifetime: number
  fuel_type: string
  lower_heating_value: number
  fuel_cost: number
  fuel_limit_enabled: boolean
  fuel_limit_max: number
}

// Main technology parameters interface
interface TechnologyParameters {
  project_id: string
  project_economic_settings: ProjectEconomicSettings
  technology_parameters: {
    solar_pv?: SolarPVParams
    wind_turbine?: WindTurbineParams
    battery?: BatteryParams
    diesel_generator?: FuelGeneratorParams
    biogas_generator?: FuelGeneratorParams
    mini_hydro?: any // Add specific type if needed
  }
  selectedComponent: string | null
}

interface TechParamsStore {
  params: TechnologyParameters
  updateEconomicSettings: (settings: Partial<ProjectEconomicSettings>) => void
  updateComponentParams: (component: string, params: any) => void
  selectComponent: (component: string | null) => void
  submitParams: () => Promise<void>
}

// Default values
const initialParams: TechnologyParameters = {
  project_id: "abc123", // This would normally come from the previous step
  project_economic_settings: {
    discount_rate: 6.5,
    currency: "USD",
  },
  technology_parameters: {
    solar_pv: {
      investment_cost: 1000.0,
      operation_cost: 2.0,
      subsidy: 10.0,
      lifetime: 25,
    },
    battery: {
      nominal_capacity: 10.0,
      investment_cost: 400.0,
      operation_cost: 1.5,
      lifetime: 10,
      charge_time: 5.0,
      discharge_time: 5.0,
      charging_efficiency: 95.0,
      discharging_efficiency: 95.0,
      soc_min: 20.0,
      soc_max: 90.0,
      soc_initial: 50.0,
    },
    diesel_generator: {
      nominal_capacity: 5.0,
      nominal_efficiency: 30.0,
      partial_load_enabled: true,
      efficiency_samples: 5,
      investment_cost: 500.0,
      operation_cost: 3.0,
      lifetime: 15,
      fuel_type: "diesel",
      lower_heating_value: 10.5,
      fuel_cost: 1.0,
      fuel_limit_enabled: true,
      fuel_limit_max: 1000.0,
    },
  },
  selectedComponent: null,
}

export const useTechParamsStore = create<TechParamsStore>((set, get) => ({
  params: initialParams,

  updateEconomicSettings: (settings) =>
    set((state) => ({
      params: {
        ...state.params,
        project_economic_settings: {
          ...state.params.project_economic_settings,
          ...settings,
        },
      },
    })),

  updateComponentParams: (component, params) =>
    set((state) => ({
      params: {
        ...state.params,
        technology_parameters: {
          ...state.params.technology_parameters,
          [component]: {
            ...state.params.technology_parameters[component as keyof typeof state.params.technology_parameters],
            ...params,
          },
        },
      },
    })),

  selectComponent: (component) =>
    set((state) => ({
      params: {
        ...state.params,
        selectedComponent: component,
      },
    })),

  submitParams: async () => {
    const { params } = get()

    try {
      // In a real app, this would be an API call
      const response = await fetch("/api/technology-parameters", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(params),
      })

      if (!response.ok) {
        throw new Error("Failed to submit technology parameters")
      }

      return Promise.resolve()
    } catch (error) {
      console.error("Error submitting technology parameters:", error)
      return Promise.reject(error)
    }
  },
}))
