// Supabase Edge Function: send-agency-otp
// Deploy to: https://supabase.com/docs/guides/functions/deploy
// Path: supabase/functions/send-agency-otp/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { sendEmail } from "../_shared/email.ts";

interface RequestBody {
  email: string;
  agencyName: string;
  otp: string;
  type: "registration" | "resend";
}

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { email, agencyName, otp, type } = (await req.json()) as RequestBody;

    // Validate input
    if (!email || !agencyName || !otp) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const subject =
      type === "registration"
        ? "Bhromon: Verify Your Agency Account"
        : "Bhromon: Your OTP Code";

    const htmlContent = generateEmailHTML(agencyName, otp, type);

    // Send email via Resend, SendGrid, or your email service
    const result = await sendEmail({
      to: email,
      subject,
      html: htmlContent,
    });

    return new Response(JSON.stringify({ success: true, result }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Email send error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Failed to send email" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});

// ========================
// EMAIL HTML TEMPLATE
// ========================

function generateEmailHTML(
  agencyName: string,
  otp: string,
  type: "registration" | "resend"
): string {
  const heading =
    type === "registration"
      ? "Welcome to Bhromon! 🎉"
      : "Your OTP Code";

  const message =
    type === "registration"
      ? `Your agency <strong>${agencyName}</strong> has been successfully registered on Bhromon. Please verify your email to complete the setup.`
      : `We received a request to verify your email. Your verification code is below.`;

  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: #f5f5f5;
          }
          .container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .header {
            text-align: center;
            margin-bottom: 30px;
          }
          .logo {
            font-size: 28px;
            font-weight: bold;
            color: #6366f1;
          }
          h1 {
            color: #1f2937;
            margin-top: 20px;
            margin-bottom: 10px;
          }
          .subtitle {
            color: #6b7280;
            font-size: 14px;
          }
          .content {
            margin: 30px 0;
            color: #374151;
            line-height: 1.8;
          }
          .otp-box {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            padding: 30px;
            border-radius: 8px;
            text-align: center;
            margin: 30px 0;
          }
          .otp-code {
            font-size: 36px;
            font-weight: bold;
            color: white;
            letter-spacing: 8px;
            font-family: monospace;
          }
          .otp-note {
            color: #e0e7ff;
            font-size: 12px;
            margin-top: 10px;
          }
          .footer {
            border-top: 1px solid #e5e7eb;
            padding-top: 20px;
            margin-top: 30px;
            color: #9ca3af;
            font-size: 12px;
            text-align: center;
          }
          .button {
            display: inline-block;
            background: #6366f1;
            color: white;
            padding: 12px 30px;
            border-radius: 6px;
            text-decoration: none;
            margin-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="logo">Bhromon</div>
            <h1>${heading}</h1>
            <p class="subtitle">Travel Made Social</p>
          </div>

          <div class="content">
            <p>${message}</p>
          </div>

          <div class="otp-box">
            <div class="otp-code">${otp}</div>
            <div class="otp-note">This code expires in 10 minutes</div>
          </div>

          <div class="content">
            <p>If you didn't request this code, please ignore this email.</p>
            <p>
              Questions? Contact us at 
              <a href="mailto:support@bhromon.com">support@bhromon.com</a>
            </p>
          </div>

          <div class="footer">
            <p>&copy; 2024 Bhromon. All rights reserved.</p>
            <p>
              <a href="https://bhromon.com/privacy" style="color: #9ca3af;">Privacy Policy</a> | 
              <a href="https://bhromon.com/terms" style="color: #9ca3af;">Terms of Service</a>
            </p>
          </div>
        </div>
      </body>
    </html>
  `;
}

// ========================
// CORS HEADERS
// ========================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};