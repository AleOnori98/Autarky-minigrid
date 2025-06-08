"use client";

import type React from "react";
import { useState, useEffect } from "react";
import Link from "next/link";
import dynamic from "next/dynamic";
import Image from "next/image";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useProjectStore } from "@/lib/store";
import { useRouter } from "next/navigation";

// Dynamically import MapComponent with ssr disabled
const MapComponent = dynamic(() => import("@/components/map-component"), {
  ssr: false,
});

export default function ProjectSetupPage() {
  const router = useRouter();
  const { projectData, updateProjectData, submitProject } = useProjectStore();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);

    // Only run geolocation code on client side
    if (typeof window !== "undefined" && navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          updateProjectData({
            location: {
              latitude: position.coords.latitude,
              longitude: position.coords.longitude,
            },
          });
        },
        (error) => {
          console.log("Error getting location:", error);
          // Default to Kenya coordinates if location access is denied
          updateProjectData({
            location: {
              latitude: -2.05627616659381,
              longitude: 41.11023900111167,
            },
          });
        }
      );
    }
  }, [updateProjectData]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await submitProject();
      // Navigate to next step
      router.push("/system-configuration");
    } catch (error) {
      console.error("Error submitting project:", error);
    }
  };

  const handleLocationChange = (lat: number, lng: number) => {
    updateProjectData({
      location: {
        latitude: lat,
        longitude: lng,
      },
    });
  };

  if (!mounted) {
    return <div>Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-[#FABC5F] px-6 py-4">
        <div className="flex items-center justify-between max-w-7xl mx-auto">
          <div className="flex items-center space-x-2">
            <div className="">
              {" "}
              <div className="">
                <Image
                  src="/Asset2.svg"
                  alt="Autarky Logo"
                  width={40}
                  height={40}
                  className="h-10 w-10 "
                />
              </div>
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
            <h2 className="text-xl font-bold">Project Setup</h2>
            <span className="text-sm text-gray-600">Step 1 of 5</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-black h-2 rounded-full"
              style={{ width: "20%" }}
            ></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <p className="text-lg mb-8 max-w-4xl">
          Welcome to the Project Setup page, here you can create a new modeling
          project by defining its name, location, simulation horizon, and time
          resolution to lay the foundation for your energy system analysis.
        </p>

        <form
          onSubmit={handleSubmit}
          className="grid grid-cols-1 lg:grid-cols-2 gap-12"
        >
          {/* Left Column - Map and Location */}
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold mb-4">
                Pinpoint your case study location by clicking on the map or
                entering coordinates below.
              </h3>

              <div className="grid grid-cols-2 gap-4 mb-4">
                <div>
                  <Label htmlFor="latitude">Latitude:</Label>
                  <Input
                    id="latitude"
                    type="number"
                    step="any"
                    value={projectData.location.latitude}
                    onChange={(e) =>
                      handleLocationChange(
                        Number.parseFloat(e.target.value) || 0,
                        projectData.location.longitude
                      )
                    }
                    className="mt-1"
                  />
                </div>
                <div>
                  <Label htmlFor="longitude">Longitude:</Label>
                  <Input
                    id="longitude"
                    type="number"
                    step="any"
                    value={projectData.location.longitude}
                    onChange={(e) =>
                      handleLocationChange(
                        projectData.location.latitude,
                        Number.parseFloat(e.target.value) || 0
                      )
                    }
                    className="mt-1"
                  />
                </div>
              </div>

              <div className="w-full h-96 border rounded-lg overflow-hidden">
                <MapComponent
                  latitude={projectData.location.latitude}
                  longitude={projectData.location.longitude}
                  onLocationChange={handleLocationChange}
                />
              </div>
            </div>
          </div>

          {/* Right Column - Form Fields */}
          <div className="space-y-6">
            <div>
              <Label htmlFor="projectName" className="text-lg font-semibold">
                Project Name
              </Label>
              <Input
                id="projectName"
                value={projectData.project_name}
                onChange={(e) =>
                  updateProjectData({ project_name: e.target.value })
                }
                className="mt-2"
                placeholder="Enter project name"
              />
            </div>

            <div>
              <Label htmlFor="description" className="text-lg font-semibold">
                Description
              </Label>
              <Textarea
                id="description"
                value={projectData.description}
                onChange={(e) =>
                  updateProjectData({ description: e.target.value })
                }
                className="mt-2 min-h-24"
                placeholder="Enter project description"
              />
            </div>

            <div>
              <h3 className="text-lg font-semibold mb-4">Time Settings</h3>
              <p className="text-gray-600 mb-4">
                Define how long and how detailed your simulation will be:
              </p>

              <div className="grid grid-cols-2 gap-6">
                <div>
                  <Label htmlFor="timeHorizon">Time Horizon:</Label>
                  <Input
                    id="timeHorizon"
                    type="number"
                    min="1"
                    max="50"
                    value={projectData.time_horizon}
                    onChange={(e) =>
                      updateProjectData({
                        time_horizon: Number.parseInt(e.target.value) || 10,
                      })
                    }
                    className="mt-1"
                  />
                  <span className="text-sm text-gray-500">years</span>
                </div>

                <div>
                  <Label htmlFor="timeResolution">Time Resolution:</Label>
                  <Select
                    value={projectData.time_resolution}
                    onValueChange={(value) =>
                      updateProjectData({ time_resolution: value })
                    }
                  >
                    <SelectTrigger className="mt-1">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="hours">Hourly</SelectItem>
                      <SelectItem value="30-minutes">30 Minutes</SelectItem>
                      <SelectItem value="15-minutes">15 Minutes</SelectItem>
                      <SelectItem value="minute">Minute</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="mt-6 space-y-4">
                <div className="flex items-center space-x-2">
                  <Checkbox
                    id="seasonality"
                    checked={projectData.seasonality_enabled}
                    onCheckedChange={(checked) =>
                      updateProjectData({
                        seasonality_enabled: checked as boolean,
                      })
                    }
                  />
                  <Label htmlFor="seasonality">Seasonality:</Label>
                </div>

                {projectData.seasonality_enabled && (
                  <div>
                    <Label htmlFor="seasonalityOption">
                      Number of seasons:
                    </Label>
                    <Select
                      value={projectData.seasonality_option}
                      onValueChange={(value) =>
                        updateProjectData({ seasonality_option: value })
                      }
                    >
                      <SelectTrigger className="mt-1 max-w-48">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="2 seasons">2 seasons</SelectItem>
                        <SelectItem value="4 seasons">4 seasons</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                )}
              </div>
            </div>
          </div>
        </form>

        {/* Navigation Buttons - Fixed positioning at the bottom right */}
        <div className="flex justify-end mt-12 space-x-4">
          <Link href="/components">
            <Button variant="outline" className="px-8 py-2">
              Back
            </Button>
          </Link>
          <Button
            type="submit"
            onClick={handleSubmit}
            className="bg-black hover:bg-gray-800 text-white px-8 py-2"
          >
            Next
          </Button>
        </div>
      </main>
    </div>
  );
}
