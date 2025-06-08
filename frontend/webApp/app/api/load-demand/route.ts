import { type NextRequest, NextResponse } from "next/server"

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { project_id, load_profile } = body

    if (!project_id || !load_profile) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    console.log("Received load demand data:", body)

    // Simulate API processing
    await new Promise((resolve) => setTimeout(resolve, 1000))

    return NextResponse.json({
      status: "ok",
      message: "Load demand saved successfully",
      project_id: project_id,
    })
  } catch (error) {
    console.error("Error processing load demand:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
