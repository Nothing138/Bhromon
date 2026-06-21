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
    // Database থেকে pending agencies নাও
    const { data, error } = await supabase
      .from('travel_agencies')
      .select('*')
      .eq('verification_status', 'waiting') // Status: waiting
      .order('created_at', { ascending: false }); // নতুনটা আগে

    if (error) throw error;

    return new Response(
      JSON.stringify({
        success: true,
        count: data.length,
        agencies: data,
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