import Image from "next/image"
import { Button } from "@/components/ui/button"

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-red-500 text-white px-4 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-white rounded-full flex items-center justify-center">
              <span className="text-red-500 font-bold text-sm">logo</span>
            </div>
            <h1 className="text-2xl font-bold">Autarky</h1>
          </div>
          <nav className="hidden md:flex items-center gap-8">
            <a href="#" className="text-white hover:text-red-100 transition-colors">
              Who we are
            </a>
            <a href="#" className="text-white hover:text-red-100 transition-colors">
              Contact us
            </a>
            <a href="#" className="text-white hover:text-red-100 transition-colors">
              Resources
            </a>
          </nav>
          {/* Mobile menu button */}
          <button className="md:hidden text-white">
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-12 lg:py-20">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left Content */}
          <div className="space-y-8">
            <div className="space-y-6">
              <h2 className="text-4xl lg:text-5xl xl:text-6xl font-bold leading-tight">
                Get Started <br className="hidden sm:block" />
                with <span className="text-red-500">Autarky</span>!
              </h2>

              <div className="space-y-4">
                <p className="text-xl lg:text-2xl font-medium text-gray-800">
                  Open-Source <em>Tools for</em>
                </p>
                <p className="text-xl lg:text-2xl font-medium text-gray-800">Designing & Operating</p>
                <p className="text-xl lg:text-2xl font-medium text-gray-800">
                  Mini-Grids <em>and</em> Swarm Grids
                </p>
                <p className="text-xl lg:text-2xl font-medium text-gray-800">under uncertainties</p>
              </div>

              <Button
                size="lg"
                className="bg-red-500 hover:bg-red-600 text-white px-8 py-4 text-lg font-semibold rounded-lg"
              >
                Get Started
              </Button>
            </div>

            <div className="space-y-4 text-gray-700 leading-relaxed">
              <p>
                Autarky has employed stochastic optimization methods and tools to{" "}
                <strong>quantify and manage energy supply reliability</strong>, including preventive, corrective, and
                restorative actions, alongside preparedness measures and dispatch strategies for{" "}
                <strong>decentralized energy systems' components</strong>.
              </p>
            </div>
          </div>

          {/* Right Content - Dashboard Preview */}
          <div className="space-y-6">
            <div className="relative">
              <Image
                src="/dashboard-preview.png"
                alt="Autarky Dashboard showing energy grid maps, network diagrams, and power consumption charts over time"
                width={600}
                height={400}
                className="w-full h-auto rounded-lg shadow-lg"
                priority
              />
            </div>

            <div className="text-center">
              <p className="text-lg lg:text-xl font-medium text-gray-800 italic">
                Model, optimize, and manage decentralized energy systems
                <br />
                under uncertainty, fully open, fully yours.
              </p>
            </div>
          </div>
        </div>

        {/* Contributors Section */}
        <div className="mt-20 pt-12 border-t-2 border-gray-300">
          <div className="text-center space-y-8">
            <h3 className="text-xl font-bold text-gray-800 tracking-wider">CONTRIBUTORS:</h3>

            <div className="flex flex-wrap justify-center items-center gap-8 lg:gap-12">
              {/* NTNU Logo */}
              <div className="flex items-center gap-2">
                <Image
                  src="/ntu.png"
                  alt="NTNU Logo"
                  width={100}
                  height={50}
                  className="h-12 w-auto"
                />
              
              </div>
              <div className="bg-black text-white px-4 py-2 rounded">
                <span className="text-xl font-bold">OPEN4CEC</span>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
