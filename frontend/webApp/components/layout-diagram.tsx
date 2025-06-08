"use client"

interface LayoutDiagramProps {
  layoutId: number
  className?: string
}

export default function LayoutDiagram({ layoutId, className = "" }: LayoutDiagramProps) {
  const renderLayout = () => {
    switch (layoutId) {
      case 1: // Solar + Battery + AC Load (Fully AC Off-Grid)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="50" y="50" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="80" y="75" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Charge Controller */}
            <rect x="150" y="50" width="40" height="40" fill="#87CEEB" stroke="#000" strokeWidth="2" />
            <text x="170" y="75" textAnchor="middle" fontSize="8" fill="#000">
              CC
            </text>

            {/* Battery */}
            <rect x="250" y="50" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="280" y="75" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="200" y="150" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="230" y="175" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="200" y="230" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="230" y="255" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="70" x2="150" y2="70" stroke="#000" strokeWidth="2" />
            <line x1="190" y1="70" x2="250" y2="70" stroke="#000" strokeWidth="2" />
            <line x1="280" y1="90" x2="280" y2="130" stroke="#000" strokeWidth="2" />
            <line x1="280" y1="130" x2="230" y2="130" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="130" x2="230" y2="150" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="190" x2="230" y2="230" stroke="#000" strokeWidth="2" />

            {/* DC Bus Label */}
            <text x="200" y="25" fontSize="12" fill="#000" fontWeight="bold">
              DC Bus
            </text>
            <line x1="50" y1="30" x2="310" y2="30" stroke="#000" strokeWidth="1" strokeDasharray="5,5" />

            {/* AC Bus Label */}
            <text x="200" y="210" fontSize="12" fill="#000" fontWeight="bold">
              AC Bus
            </text>
            <line x1="150" y1="215" x2="310" y2="215" stroke="#000" strokeWidth="1" strokeDasharray="5,5" />
          </svg>
        )

      case 2: // Solar + Battery + Grid (Fully AC On-Grid)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="30" y="50" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="60" y="75" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Battery */}
            <rect x="130" y="50" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="160" y="75" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Grid Connection */}
            <rect x="30" y="150" width="60" height="40" fill="#FF6347" stroke="#000" strokeWidth="2" />
            <text x="60" y="175" textAnchor="middle" fontSize="10" fill="#000">
              Grid
            </text>

            {/* Inverter */}
            <rect x="170" y="150" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="175" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="300" y="150" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="330" y="175" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="90" y1="70" x2="130" y2="70" stroke="#000" strokeWidth="2" />
            <line x1="160" y1="90" x2="160" y2="130" stroke="#000" strokeWidth="2" />
            <line x1="160" y1="130" x2="200" y2="130" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="130" x2="200" y2="150" stroke="#000" strokeWidth="2" />
            <line x1="90" y1="170" x2="170" y2="170" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="170" x2="300" y2="170" stroke="#000" strokeWidth="2" />

            {/* AC Bus */}
            <text x="200" y="210" fontSize="12" fill="#000" fontWeight="bold">
              AC Bus
            </text>
            <line x1="30" y1="215" x2="360" y2="215" stroke="#000" strokeWidth="1" strokeDasharray="5,5" />
          </svg>
        )

      case 3: // Hybrid AC Mini-Grid (Solar + Diesel + Battery)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="30" y="30" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="60" y="55" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Diesel Generator */}
            <rect x="30" y="100" width="60" height="40" fill="#8B4513" stroke="#000" strokeWidth="2" />
            <text x="60" y="125" textAnchor="middle" fontSize="10" fill="#000">
              Diesel
            </text>

            {/* Battery */}
            <rect x="170" y="65" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="200" y="90" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="170" y="170" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="195" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="300" y="170" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="330" y="195" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="90" y1="50" x2="170" y2="85" stroke="#000" strokeWidth="2" />
            <line x1="90" y1="120" x2="170" y2="85" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="105" x2="200" y2="170" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="190" x2="300" y2="190" stroke="#000" strokeWidth="2" />
          </svg>
        )

      case 4: // Fully Renewable AC Mini-Grid (Solar + Wind + Battery)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="30" y="30" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="60" y="55" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Wind Turbine */}
            <rect x="30" y="100" width="60" height="40" fill="#87CEEB" stroke="#000" strokeWidth="2" />
            <text x="60" y="125" textAnchor="middle" fontSize="10" fill="#000">
              Wind
            </text>

            {/* Battery */}
            <rect x="170" y="65" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="200" y="90" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="170" y="170" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="195" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="300" y="170" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="330" y="195" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="90" y1="50" x2="170" y2="85" stroke="#000" strokeWidth="2" />
            <line x1="90" y1="120" x2="170" y2="85" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="105" x2="200" y2="170" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="190" x2="300" y2="190" stroke="#000" strokeWidth="2" />

            {/* Labels */}
            <text x="200" y="25" fontSize="12" fill="#000" fontWeight="bold">
              100% Renewable
            </text>
          </svg>
        )

      case 5: // DC Microgrid (Solar + Battery + DC Load)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="50" y="80" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="80" y="105" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Charge Controller */}
            <rect x="150" y="80" width="40" height="40" fill="#87CEEB" stroke="#000" strokeWidth="2" />
            <text x="170" y="105" textAnchor="middle" fontSize="8" fill="#000">
              CC
            </text>

            {/* Battery */}
            <rect x="230" y="80" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="260" y="105" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* DC Load */}
            <rect x="230" y="180" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="260" y="205" textAnchor="middle" fontSize="10" fill="#000">
              DC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="100" x2="150" y2="100" stroke="#000" strokeWidth="2" />
            <line x1="190" y1="100" x2="230" y2="100" stroke="#000" strokeWidth="2" />
            <line x1="260" y1="120" x2="260" y2="180" stroke="#000" strokeWidth="2" />

            {/* DC Bus Label */}
            <text x="200" y="50" fontSize="12" fill="#000" fontWeight="bold">
              DC Bus Only
            </text>
            <line x1="50" y1="55" x2="290" y2="55" stroke="#000" strokeWidth="1" strokeDasharray="5,5" />
          </svg>
        )

      case 6: // Hydro + Battery + AC Load
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Mini-Hydro */}
            <rect x="50" y="80" width="60" height="40" fill="#4682B4" stroke="#000" strokeWidth="2" />
            <text x="80" y="105" textAnchor="middle" fontSize="10" fill="#fff">
              Mini-Hydro
            </text>

            {/* Battery */}
            <rect x="170" y="80" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="200" y="105" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="170" y="170" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="195" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="290" y="170" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="320" y="195" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="100" x2="170" y2="100" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="120" x2="200" y2="170" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="190" x2="290" y2="190" stroke="#000" strokeWidth="2" />
          </svg>
        )

      case 7: // Solar + Battery + DC + AC Loads
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="50" y="50" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="80" y="75" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Battery */}
            <rect x="170" y="50" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="200" y="75" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="120" y="150" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="150" y="175" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* DC Load */}
            <rect x="270" y="50" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="300" y="75" textAnchor="middle" fontSize="10" fill="#000">
              DC Load
            </text>

            {/* AC Load */}
            <rect x="220" y="150" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="250" y="175" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="70" x2="170" y2="70" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="70" x2="270" y2="70" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="90" x2="200" y2="130" stroke="#000" strokeWidth="2" />
            <line x1="150" y1="130" x2="200" y2="130" stroke="#000" strokeWidth="2" />
            <line x1="150" y1="130" x2="150" y2="150" stroke="#000" strokeWidth="2" />
            <line x1="180" y1="170" x2="220" y2="170" stroke="#000" strokeWidth="2" />

            {/* Bus Labels */}
            <text x="200" y="25" fontSize="12" fill="#000" fontWeight="bold">
              DC Bus
            </text>
            <text x="200" y="210" fontSize="12" fill="#000" fontWeight="bold">
              AC Bus
            </text>
          </svg>
        )

      case 8: // Wind + Battery + AC Load (Off-Grid)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Wind Turbine */}
            <rect x="50" y="80" width="60" height="40" fill="#87CEEB" stroke="#000" strokeWidth="2" />
            <text x="80" y="105" textAnchor="middle" fontSize="10" fill="#000">
              Wind
            </text>

            {/* Battery */}
            <rect x="170" y="80" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="200" y="105" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="170" y="170" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="195" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="290" y="170" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="320" y="195" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="100" x2="170" y2="100" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="120" x2="200" y2="170" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="190" x2="290" y2="190" stroke="#000" strokeWidth="2" />
          </svg>
        )

      case 9: // Biogas + Battery + AC Load
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Biogas Generator */}
            <rect x="50" y="80" width="60" height="40" fill="#228B22" stroke="#000" strokeWidth="2" />
            <text x="80" y="105" textAnchor="middle" fontSize="10" fill="#fff">
              Biogas
            </text>

            {/* Battery */}
            <rect x="170" y="80" width="60" height="40" fill="#90EE90" stroke="#000" strokeWidth="2" />
            <text x="200" y="105" textAnchor="middle" fontSize="10" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="170" y="170" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="195" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="290" y="170" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="320" y="195" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="100" x2="170" y2="100" stroke="#000" strokeWidth="2" />
            <line x1="200" y1="120" x2="200" y2="170" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="190" x2="290" y2="190" stroke="#000" strokeWidth="2" />
          </svg>
        )

      case 10: // On-Grid + Diesel Backup + AC Load
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Grid Connection */}
            <rect x="50" y="80" width="60" height="40" fill="#FF6347" stroke="#000" strokeWidth="2" />
            <text x="80" y="105" textAnchor="middle" fontSize="10" fill="#fff">
              Grid
            </text>

            {/* Diesel Generator */}
            <rect x="50" y="150" width="60" height="40" fill="#8B4513" stroke="#000" strokeWidth="2" />
            <text x="80" y="175" textAnchor="middle" fontSize="10" fill="#fff">
              Diesel
            </text>

            {/* Inverter */}
            <rect x="170" y="115" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="140" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="290" y="115" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="320" y="140" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="100" x2="170" y2="135" stroke="#000" strokeWidth="2" />
            <line x1="110" y1="170" x2="170" y2="135" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="135" x2="290" y2="135" stroke="#000" strokeWidth="2" />

            {/* Backup Label */}
            <text x="80" y="210" fontSize="10" fill="#000" textAnchor="middle">
              Backup Power
            </text>
          </svg>
        )

      case 11: // Solar + Biogas + Grid + Battery + AC Load
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="20" y="30" width="50" height="30" fill="#FFD700" stroke="#000" strokeWidth="1" />
            <text x="45" y="50" textAnchor="middle" fontSize="8" fill="#000">
              Solar
            </text>

            {/* Biogas Generator */}
            <rect x="20" y="80" width="50" height="30" fill="#228B22" stroke="#000" strokeWidth="1" />
            <text x="45" y="100" textAnchor="middle" fontSize="8" fill="#fff">
              Biogas
            </text>

            {/* Grid Connection */}
            <rect x="20" y="130" width="50" height="30" fill="#FF6347" stroke="#000" strokeWidth="1" />
            <text x="45" y="150" textAnchor="middle" fontSize="8" fill="#fff">
              Grid
            </text>

            {/* Battery */}
            <rect x="120" y="80" width="50" height="30" fill="#90EE90" stroke="#000" strokeWidth="1" />
            <text x="145" y="100" textAnchor="middle" fontSize="8" fill="#000">
              Battery
            </text>

            {/* Inverter */}
            <rect x="220" y="80" width="50" height="30" fill="#FFA500" stroke="#000" strokeWidth="1" />
            <text x="245" y="100" textAnchor="middle" fontSize="8" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="320" y="80" width="50" height="30" fill="#DDA0DD" stroke="#000" strokeWidth="1" />
            <text x="345" y="100" textAnchor="middle" fontSize="8" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="70" y1="45" x2="120" y2="95" stroke="#000" strokeWidth="1" />
            <line x1="70" y1="95" x2="120" y2="95" stroke="#000" strokeWidth="1" />
            <line x1="70" y1="145" x2="120" y2="95" stroke="#000" strokeWidth="1" />
            <line x1="170" y1="95" x2="220" y2="95" stroke="#000" strokeWidth="1" />
            <line x1="270" y1="95" x2="320" y2="95" stroke="#000" strokeWidth="1" />

            {/* Complex System Label */}
            <text x="200" y="20" fontSize="10" fill="#000" fontWeight="bold" textAnchor="middle">
              Hybrid System
            </text>
          </svg>
        )

      case 12: // Solar + Diesel + AC Load (No battery)
        return (
          <svg viewBox="0 0 400 300" className={`w-full h-full ${className}`}>
            {/* Solar PV */}
            <rect x="50" y="60" width="60" height="40" fill="#FFD700" stroke="#000" strokeWidth="2" />
            <text x="80" y="85" textAnchor="middle" fontSize="10" fill="#000">
              Solar PV
            </text>

            {/* Diesel Generator */}
            <rect x="50" y="140" width="60" height="40" fill="#8B4513" stroke="#000" strokeWidth="2" />
            <text x="80" y="165" textAnchor="middle" fontSize="10" fill="#fff">
              Diesel
            </text>

            {/* Inverter */}
            <rect x="170" y="100" width="60" height="40" fill="#FFA500" stroke="#000" strokeWidth="2" />
            <text x="200" y="125" textAnchor="middle" fontSize="10" fill="#000">
              Inverter
            </text>

            {/* AC Load */}
            <rect x="290" y="100" width="60" height="40" fill="#DDA0DD" stroke="#000" strokeWidth="2" />
            <text x="320" y="125" textAnchor="middle" fontSize="10" fill="#000">
              AC Load
            </text>

            {/* Connections */}
            <line x1="110" y1="80" x2="170" y2="120" stroke="#000" strokeWidth="2" />
            <line x1="110" y1="160" x2="170" y2="120" stroke="#000" strokeWidth="2" />
            <line x1="230" y1="120" x2="290" y2="120" stroke="#000" strokeWidth="2" />

            {/* No Battery Label */}
            <text x="200" y="50" fontSize="12" fill="#000" fontWeight="bold" textAnchor="middle">
              No Storage
            </text>
          </svg>
        )

      default:
        return (
          <div className="flex items-center justify-center h-full text-gray-500">
            <span>Layout diagram not available</span>
          </div>
        )
    }
  }

  return <div className="w-full h-full">{renderLayout()}</div>
}
