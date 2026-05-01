import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

// This route runs SERVER-SIDE with the service role key, bypassing RLS.
// The website's anon key cannot update other users' profiles — this does.
const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // Never expose this client-side
  { auth: { persistSession: false } }
);

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { terminalId, userId, protocolId, protocolTitle, durationDays, paymentId } = body;

    if (!terminalId || !userId || !protocolId) {
      return NextResponse.json({ error: "MISSING_REQUIRED_FIELDS" }, { status: 400 });
    }

    // 1. Update the user's profile — this requires service role since anon can't update others
    const { error: profileError } = await supabaseAdmin
      .from("profiles")
      .update({
        is_paid: true,
        protocol_id: protocolId,
        protocol_start_date: new Date().toISOString(),
      })
      .eq("id", userId);

    if (profileError) {
      console.error("Profile update failed:", profileError);
      return NextResponse.json(
        { error: `PROFILE_UPDATE_FAILED: ${profileError.message}` },
        { status: 500 }
      );
    }

    // 2. Update the terminal status to AUTHORIZED — signals the mobile app
    const { error: terminalError } = await supabaseAdmin
      .from("terminals")
      .update({
        status: "AUTHORIZED",
        updated_at: new Date().toISOString(),
      })
      .eq("id", terminalId);

    if (terminalError) {
      console.error("Terminal update failed:", terminalError);
      return NextResponse.json(
        { error: `TERMINAL_UPDATE_FAILED: ${terminalError.message}` },
        { status: 500 }
      );
    }

    console.log(`Payment authorized: userId=${userId}, protocol=${protocolTitle}, payment=${paymentId}`);
    return NextResponse.json({ success: true });
  } catch (err: any) {
    console.error("Authorize route error:", err);
    return NextResponse.json({ error: err.message || "INTERNAL_ERROR" }, { status: 500 });
  }
}
