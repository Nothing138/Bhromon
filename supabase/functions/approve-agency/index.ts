import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// OTP Generate করার function
function generateOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Main function - এটাই execute হবে যখন call করবো
Deno.serve(async (req) => {
  // CORS handling (Flutter থেকে request আসলে কাজ করবে)
  if (req.method === 'OPTIONS') {
    return new Response('OK', { 
      headers: { 'Access-Control-Allow-Origin': '*' } 
    });
  }

  try {
    // Request থেকে data নিও
    const { agencyId, adminUserId, adminNotes } = await req.json();

    // Validation
    if (!agencyId || !adminUserId) {
      return new Response(
        JSON.stringify({ error: 'Missing agencyId or adminUserId' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Database থেকে agency এর details নাও
    const { data: agency, error: fetchError } = await supabase
      .from('travel_agencies')
      .select('owner_email, agency_name')
      .eq('id', agencyId)
      .single();

    if (fetchError) throw fetchError;

    // OTP generate করো
    const otp = generateOtp();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 10); // 10 minute expiry

    // OTP database এ save করো
    const { error: otpError } = await supabase
      .from('agency_otp')
      .insert({
        agency_id: agencyId,
        otp_code: otp,
        expires_at: expiresAt.toISOString(),
      });

    if (otpError) throw otpError;

    // Agency status update করো (approved)
    const { error: updateError } = await supabase
      .from('travel_agencies')
      .update({
        verification_status: 'approved',
        verification_notes: adminNotes,
        verified_by_admin_id: adminUserId,
        verified_at: new Date().toISOString(),
      })
      .eq('id', agencyId);

    if (updateError) throw updateError;

    // Log করো console এ (email sending এর জন্য placeholder)
    console.log(`✅ Agency Approved!`);
    console.log(`📧 Would send OTP to: ${agency.owner_email}`);
    console.log(`🔐 OTP: ${otp}`);

    // Success response পাঠাও
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Agency approved! OTP generated!',
        otp: otp, // Testing এর জন্য - production এ remove করবো
      }),
      { 
        status: 200, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        } 
      }
    );

  } catch (error) {
    console.error('❌ Error:', error);
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        } 
      }
    );
  }
});