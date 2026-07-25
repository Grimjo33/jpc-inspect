const json=(res,status,body)=>{res.setHeader('Cache-Control','no-store');res.setHeader('Content-Type','application/json');return res.status(status).json(body)};
const parseBody=req=>typeof req.body==='string'?JSON.parse(req.body||'{}'):(req.body||{});
const request=async(url,options)=>{const response=await fetch(url,options);const data=await response.json().catch(()=>({}));if(!response.ok){const error=new Error(data.msg||data.message||data.error_description||data.error||'Permintaan Supabase gagal');error.status=response.status;throw error}return data};
export default async function handler(req,res){
 if(req.method!=='POST')return json(res,405,{error:'Metode tidak diizinkan'});
 const base=process.env.SUPABASE_URL,anon=process.env.SUPABASE_ANON_KEY,service=process.env.SUPABASE_SERVICE_ROLE_KEY;
 if(!base||!anon||!service)return json(res,503,{error:'Pembuatan pengguna oleh Admin belum dikonfigurasi di server'});
 const authorization=req.headers.authorization||'';if(!authorization.startsWith('Bearer '))return json(res,401,{error:'Sesi Admin tidak tersedia'});
 let body;try{body=parseBody(req)}catch{return json(res,400,{error:'Data pengguna tidak valid'})}
 const email=String(body.email||'').trim().toLowerCase(),fullName=String(body.full_name||'').trim(),department=String(body.department||'').trim(),password=String(body.password||'');
 if(!email.endsWith('@jambiprimacoal.co.id'))return json(res,400,{error:'Gunakan email PT Jambi Prima Coal'});
 if(!fullName||!department)return json(res,400,{error:'Nama dan departemen wajib diisi'});
 if(password.length<10)return json(res,400,{error:'Password sementara minimal 10 karakter'});
 const serviceHeaders={apikey:service,Authorization:`Bearer ${service}`,'Content-Type':'application/json'};let createdUser;
 try{
  const caller=await request(`${base}/auth/v1/user`,{headers:{apikey:anon,Authorization:authorization}});
  const profiles=await request(`${base}/rest/v1/profiles?id=eq.${encodeURIComponent(caller.id)}&select=id,role,active`,{headers:serviceHeaders});
  const admin=profiles[0];if(!admin?.active||admin.role!=='admin')return json(res,403,{error:'Hanya Admin aktif yang dapat menambah pengguna'});
  createdUser=await request(`${base}/auth/v1/admin/users`,{method:'POST',headers:serviceHeaders,body:JSON.stringify({email,password,email_confirm:true,user_metadata:{full_name:fullName,department}})});
  const user=createdUser.user||createdUser;
  await request(`${base}/rest/v1/profiles?on_conflict=id`,{method:'POST',headers:{...serviceHeaders,Prefer:'resolution=merge-duplicates,return=representation'},body:JSON.stringify({id:user.id,full_name:fullName,department,role:'viewer',active:true})});
  await request(`${base}/rest/v1/audit_logs`,{method:'POST',headers:{...serviceHeaders,Prefer:'return=minimal'},body:JSON.stringify({entity_type:'profile',entity_id:user.id,action:'user_created_by_admin',new_data:{email,full_name:fullName,department,role:'viewer',email_confirmed:true},actor_id:caller.id,reason:'Admin provisioning'})});
  return json(res,201,{created:true,user:{id:user.id,email,full_name:fullName,department,role:'viewer',active:true}});
 }catch(error){
  if(createdUser){const user=createdUser.user||createdUser;await fetch(`${base}/auth/v1/admin/users/${encodeURIComponent(user.id)}`,{method:'DELETE',headers:serviceHeaders}).catch(()=>{})}
  const status=error.status===422||error.status===400?409:error.status===401?401:500;
  return json(res,status,{error:status===409?'Email sudah terdaftar atau data akun tidak dapat digunakan':error.message});
 }
}
