import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { project_id, selected_model, parameters } = body

    if (!project_id || !selected_model) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    console.log("Received model uncertainties data:", body)

    // Simulate API processing
    await new Promise((resolve) => setTimeout(resolve, 1000))

    return NextResponse.json({
      status: "ok",
      message: "Model uncertainties saved successfully",
      project_id: project_id,
    })
  } catch (error) {
    console.error("Error processing model uncertainties:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
