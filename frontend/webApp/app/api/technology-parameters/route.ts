import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    // Validate the incoming data
    const { project_id, project_economic_settings, technology_parameters } = body

    // Basic validation
    if (!project_id || !project_economic_settings || !technology_parameters) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    // Here you would typically save to a database
    // For now, we'll just log and return success
    console.log("Received technology parameters data:", body)

    // Simulate API processing
    await new Promise((resolve) => setTimeout(resolve, 1000))

    return NextResponse.json({
      status: "ok",
      message: "Technology parameters saved successfully",
    })
  } catch (error) {
    console.error("Error processing technology parameters:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
