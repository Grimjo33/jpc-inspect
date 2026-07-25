import{rest}from'./supabase.js';

const roleLabels={admin:'Admin',ktt_ptl:'KTT / PTL',inspector:'Inspector',pic:'PIC',verifier:'Verifier',viewer:'Viewer'};
let people=[];

function escapeHtml(value){return String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]))}
function eligible(person,kind){
  if(kind==='inspector'||kind==='pic')return person.active;
  if(kind==='verifier')return person.active&&['admin','ktt_ptl','verifier'].includes(person.role);
  if(kind==='approver')return person.active&&['admin','ktt_ptl'].includes(person.role);
  return false;
}
function patchSelect(select,kind){
  if(!select||select.dataset.assignmentEligibility===kind)return;
  const selected=select.value;
  select.dataset.assignmentEligibility=kind;
  select.innerHTML='<option value="">Pilih personel</option>'+people.filter(person=>eligible(person,kind)).map(person=>`<option value="${person.id}" ${person.id===selected?'selected':''}>${escapeHtml(person.full_name)} · ${roleLabels[person.role]||person.role}${person.department?' · '+escapeHtml(person.department):''}</option>`).join('');
  if(selected&&people.some(person=>person.id===selected&&eligible(person,kind)))select.value=selected;
}
function patchAssignments(root=document){
  patchSelect(root.querySelector?.('select[name="assigned_inspector"]'),'inspector');
  patchSelect(root.querySelector?.('select[name="assigned_approver"]'),'approver');
  patchSelect(root.querySelector?.('#rolePic'),'pic');
  patchSelect(root.querySelector?.('#roleVerifier'),'verifier');
}

try{
  people=await rest('profiles?active=eq.true&select=id,full_name,department,role,active&order=full_name');
  patchAssignments();
  const observer=new MutationObserver(records=>{
    for(const record of records)for(const node of record.addedNodes)if(node.nodeType===1)patchAssignments(node.matches?.('select')?node.parentElement:node);
  });
  observer.observe(document.body,{childList:true,subtree:true});
}catch(error){console.error('Gagal memuat kelayakan penugasan',error)}
