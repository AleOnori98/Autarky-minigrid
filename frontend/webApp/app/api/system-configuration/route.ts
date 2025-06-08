import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    // Validate the incoming data
    const { project_id, enabled_components, layout_id } = body

    // Basic validation
    if (!project_id || !enabled_components || !layout_id) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    // Here you would typically save to a database
    // For now, we'll just log and return success
    console.log("Received system configuration data:", body)

    // Simulate API processing
    await new Promise((resolve) => setTimeout(resolve, 1000))

    return NextResponse.json({
      status: "ok",
      message: "System configuration saved successfully",
      layout_id: layout_id,
    })
  } catch (error) {
    console.error("Error processing system configuration:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
