const SUPABASE_URL = 'https://vwdtdaefjrzrnhfatktt.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_QTv2l-Px69cD6xCv3I0fJw_2HvigBJ8';
const API_BASE_URL = 'http://localhost:3000'; // Change to production Node.js URL for Hostinger deploying

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
