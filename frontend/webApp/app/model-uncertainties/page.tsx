"use client";

import type React from "react";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { Upload, Info } from "lucide-react";
import Image from "next/image";

export default function ModelUncertaintiesPage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedModel, setSelectedModel] = useState("linear");
  const [parameters, setParameters] = useState({
    expectedOutageFrequency: "",
    expectedOutageDuration: "",
    probabilityModel: "ICC",
    probabilityOfOutage: "",
    probabilityOfIslanding: "",
  });
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file && file.type === "text/csv") {
      console.log("Grid availability matrix uploaded:", file.name);
    }
  };

  const handleParameterChange = (key: string, value: string) => {
    setParameters((prev) => ({
      ...prev,
      [key]: value,
    }));
  };

  const handleSubmit = async () => {
    try {
      const response = await fetch("/api/model-uncertainties", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          project_id: "abc123",
          selected_model: selectedModel,
          parameters: parameters,
        }),
      });

      if (response.ok) {
        console.log("Model uncertainties submitted successfully");
        // Navigate to results or final page
      }
    } catch (error) {
      console.error("Error submitting model uncertainties:", error);
    }
  };

  if (!isClient) {
    return <div>Loading...</div>;
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
            <h2 className="text-xl font-bold">Model Uncertainties</h2>
            <span className="text-sm text-gray-600">Step 5 of 5</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-black h-2 rounded-full"
              style={{ width: "100%" }}
            ></div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-6 py-8">
        <p className="text-lg mb-8 max-w-4xl">
          Welcome to the Uncertainties page, here you can choose between
          different Autarky formulations of increasing computational complexity,
          from linear to advanced probabilistic models, but including more
          sources of uncertainties related to a weak connection with the main
          grid.
        </p>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Left Column - Model Selection */}
          <div className="space-y-6">
            <RadioGroup value={selectedModel} onValueChange={setSelectedModel}>
              {/* Linear Model */}
              <div
                className={`border rounded-lg p-6 ${
                  selectedModel === "linear"
                    ? "bg-blue-50 border-blue-200"
                    : "bg-white"
                }`}
              >
                <div className="flex items-center space-x-2 mb-3">
                  <RadioGroupItem value="linear" id="linear" />
                  <Label htmlFor="linear" className="text-lg font-medium">
                    Use Autarky{" "}
                    <span className="text-blue-600">Linear Model</span>
                  </Label>
                </div>
                <p className="text-sm text-gray-600">
                  The linear model uses a grid availability matrix to capture
                  deterministic limitations in grid connection, without modeling
                  randomness.
                </p>
              </div>

              {/* Expected Values Model */}
              <div
                className={`border rounded-lg p-6 ${
                  selectedModel === "expected"
                    ? "bg-blue-50 border-blue-200"
                    : "bg-white"
                }`}
              >
                <div className="flex items-center space-x-2 mb-3">
                  <RadioGroupItem value="expected" id="expected" />
                  <Label htmlFor="expected" className="text-lg font-medium">
                    Use Autarky{" "}
                    <span className="text-blue-600">Expected Values Model</span>
                  </Label>
                </div>
                <p className="text-sm text-gray-600">
                  The expected-value model incorporates forecast errors for
                  renewable production and demand by replacing random variables
                  with their expected values, simplifying the problem but
                  ignoring variability.
                </p>
              </div>

              {/* Advanced Probabilistic Models */}
              <div
                className={`border rounded-lg p-6 ${
                  selectedModel === "probabilistic"
                    ? "bg-blue-50 border-blue-200"
                    : "bg-white"
                }`}
              >
                <div className="flex items-center space-x-2 mb-3">
                  <RadioGroupItem value="probabilistic" id="probabilistic" />
                  <Label
                    htmlFor="probabilistic"
                    className="text-lg font-medium"
                  >
                    Use Autarky{" "}
                    <span className="text-blue-600">
                      Advanced Probabilistic Models
                    </span>
                  </Label>
                </div>
                <p className="text-sm text-gray-600">
                  Advanced probabilistic models apply individual (ICC) or joint
                  chance constraints (JCC) to account for forecasting errors and
                  main grid outages, explicitly incorporating the probability of
                  outage (ω) and islanding success (ρ) to ensure the system can
                  meet demand during uncertain disconnections.
                </p>
              </div>
            </RadioGroup>
          </div>

          {/* Right Column - Parameters */}
          <div className="space-y-6">
            {selectedModel === "linear" && (
              <div className="border rounded-lg p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-medium">
                    Upload Grid Availability matrix
                  </h3>
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <Info className="h-4 w-4 text-gray-400" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p>
                          CSV file containing grid availability data over time
                        </p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </div>
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
            )}

            {selectedModel === "expected" && (
              <div className="border rounded-lg p-6 space-y-4">
                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="outage-frequency">
                      Expected outage frequency:
                    </Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Average number of grid outages per time period</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Input
                    id="outage-frequency"
                    type="number"
                    value={parameters.expectedOutageFrequency}
                    onChange={(e) =>
                      handleParameterChange(
                        "expectedOutageFrequency",
                        e.target.value
                      )
                    }
                    className="mt-1"
                  />
                </div>

                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="outage-duration">
                      Expected outage duration:
                    </Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>Average duration of each grid outage</p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Input
                    id="outage-duration"
                    type="number"
                    value={parameters.expectedOutageDuration}
                    onChange={(e) =>
                      handleParameterChange(
                        "expectedOutageDuration",
                        e.target.value
                      )
                    }
                    className="mt-1"
                  />
                </div>
              </div>
            )}

            {selectedModel === "probabilistic" && (
              <div className="border rounded-lg p-6 space-y-4">
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <Label>Probability model:</Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>
                            Choose between Individual (ICC) or Joint (JCC)
                            chance constraints
                          </p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <RadioGroup
                    value={parameters.probabilityModel}
                    onValueChange={(value) =>
                      handleParameterChange("probabilityModel", value)
                    }
                    className="flex space-x-6"
                  >
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="ICC" id="icc" />
                      <Label htmlFor="icc">ICC</Label>
                    </div>
                    <div className="flex items-center space-x-2">
                      <RadioGroupItem value="JCC" id="jcc" />
                      <Label htmlFor="jcc">JCC</Label>
                    </div>
                  </RadioGroup>
                </div>

                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="probability-outage">
                      Probability of outage:
                    </Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>
                            Probability that the grid will experience an outage
                          </p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Input
                    id="probability-outage"
                    type="number"
                    step="0.01"
                    min="0"
                    max="1"
                    value={parameters.probabilityOfOutage}
                    onChange={(e) =>
                      handleParameterChange(
                        "probabilityOfOutage",
                        e.target.value
                      )
                    }
                    className="mt-1"
                  />
                </div>

                <div>
                  <div className="flex items-center justify-between">
                    <Label htmlFor="probability-islanding">
                      Probability of islanding:
                    </Label>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <Info className="h-4 w-4 text-gray-400" />
                        </TooltipTrigger>
                        <TooltipContent>
                          <p>
                            Probability that the system can successfully operate
                            in island mode
                          </p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Input
                    id="probability-islanding"
                    type="number"
                    step="0.01"
                    min="0"
                    max="1"
                    value={parameters.probabilityOfIslanding}
                    onChange={(e) =>
                      handleParameterChange(
                        "probabilityOfIslanding",
                        e.target.value
                      )
                    }
                    className="mt-1"
                  />
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Navigation Buttons */}
        <div className="flex justify-end mt-12 space-x-4">
          <Link href="/renewable-potential">
            <Button variant="outline" className="px-8 py-2">
              Back
            </Button>
          </Link>
          <Button
            onClick={handleSubmit}
            className="bg-black hover:bg-gray-800 text-white px-8 py-2"
          >
            Complete Setup
          </Button>
        </div>
      </main>
    </div>
  );
}
