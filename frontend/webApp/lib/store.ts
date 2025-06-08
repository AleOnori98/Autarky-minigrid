import { create } from "zustand"

interface Location {
  latitude: number
  longitude: number
}

interface ProjectData {
  project_name: string
  description: string
  location: Location
  time_horizon: number
  time_resolution: string
  seasonality_enabled: boolean
  seasonality_option: string
}

interface ProjectStore {
  projectData: ProjectData
  updateProjectData: (data: Partial<ProjectData>) => void
  submitProject: () => Promise<void>
  resetProject: () => void
}

const initialProjectData: ProjectData = {
  project_name: "",
  description: "",
  location: {
    latitude: -2.05627616659381,
    longitude: 41.11023900111167,
  },
  time_horizon: 20,
  time_resolution: "hours",
  seasonality_enabled: false,
  seasonality_option: "2 seasons",
}

export const useProjectStore = create<ProjectStore>((set, get) => ({
  projectData: initialProjectData,

  updateProjectData: (data) =>
    set((state) => ({
      projectData: {
        ...state.projectData,
        ...data,
        // Handle nested location object separately
        location: {
          ...state.projectData.location,
          ...(data.location || {}),
        },
      },
    })),

  submitProject: async () => {
    const { projectData } = get()

    try {
      // In a real app, this would be an API call
      console.log("Submitting project data:", projectData)

      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 500))

      return Promise.resolve()
    } catch (error) {
      console.error("Error submitting project:", error)
      return Promise.reject(error)
    }
  },

  resetProject: () => set({ projectData: initialProjectData }),
}))
