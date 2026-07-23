export default function handler(req,res){res.status(200).json({ok:true,service:'jpc-inspect',mode:process.env.SUPABASE_URL?'supabase-ready':'demo',timestamp:new Date().toISOString()});}
