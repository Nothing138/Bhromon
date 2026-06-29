import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('OK', { 
      headers: { 'Access-Control-Allow-Origin': '*' } 
    });
  }

  try {
    const { agencyId, adminUserId, reason } = await req.json();

    // Agency reject করো
    const { error } = await supabase
      .from('travel_agencies')
      .update({
        verification_status: 'rejected',
        verification_notes: reason,
        verified_by_admin_id: adminUserId,
      })
      .eq('id', agencyId);

    if (error) throw error;

    console.log(` Agency Rejected! Reason: ${reason}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Agency rejected successfully',
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
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});