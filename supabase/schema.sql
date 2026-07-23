-- JPC Inspect / Supabase PostgreSQL schema
-- Run in Supabase SQL Editor. Review role mappings and RLS before production.
create extension if not exists pgcrypto;

create type public.app_role as enum ('admin','ktt_ptl','inspector','pic','verifier','viewer');
create type public.risk_level as enum ('low','medium','high','extreme');
create type public.inspection_status as enum ('draft','planned','assigned','in_progress','submitted','reviewed','follow_up','awaiting_verification','closed','reopened','cancelled');
create type public.finding_status as enum ('open','action_in_progress','closure_requested','verification_rejected','verified','closed','reopened');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  employee_no text,
  department text,
  role public.app_role not null default 'viewer',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.areas (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  owner_id uuid references public.profiles(id),
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.inspection_objects (
  id uuid primary key default gen_random_uuid(),
  area_id uuid not null references public.areas(id),
  code text unique not null,
  name text not null,
  dominant_hazards text,
  inherent_risk public.risk_level not null,
  minimum_frequency text not null,
  last_inspected_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table public.checklist_templates (
  id uuid primary key default gen_random_uuid(),
  object_id uuid references public.inspection_objects(id),
  title text not null,
  document_no text not null,
  revision_no text not null,
  effective_date date not null,
  approved_by uuid references public.profiles(id),
  regulation_refs text[],
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(document_no,revision_no)
);
create table public.checklist_items (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.checklist_templates(id) on delete cascade,
  sequence_no integer not null,
  question text not null,
  acceptance_criteria text,
  regulation_ref text,
  critical boolean not null default false,
  unique(template_id,sequence_no)
);
create table public.inspections (
  id uuid primary key default gen_random_uuid(),
  inspection_no text unique not null,
  object_id uuid not null references public.inspection_objects(id),
  template_id uuid not null references public.checklist_templates(id),
  title text not null,
  method text not null,
  risk_level public.risk_level not null,
  inspector_id uuid not null references public.profiles(id),
  final_approver_id uuid not null references public.profiles(id),
  inspection_date timestamptz not null,
  report_due_at timestamptz not null,
  closing_due_at timestamptz not null,
  started_at timestamptz,
  submitted_at timestamptz,
  closed_at timestamptz,
  closed_by uuid references public.profiles(id),
  status public.inspection_status not null default 'planned',
  scope text,
  immediate_action_required boolean not null default false,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint closing_after_inspection check (closing_due_at >= inspection_date),
  constraint report_after_inspection check (report_due_at >= inspection_date)
);
create table public.inspection_responses (
  id uuid primary key default gen_random_uuid(),
  inspection_id uuid not null references public.inspections(id) on delete cascade,
  checklist_item_id uuid not null references public.checklist_items(id),
  result text not null check(result in ('compliant','non_compliant','na')),
  note text,
  answered_by uuid not null references public.profiles(id),
  answered_at timestamptz not null default now(),
  unique(inspection_id,checklist_item_id)
);
create table public.findings (
  id uuid primary key default gen_random_uuid(),
  finding_no text unique not null,
  inspection_id uuid not null references public.inspections(id) on delete cascade,
  response_id uuid references public.inspection_responses(id),
  title text not null,
  description text not null,
  finding_type text not null check(finding_type in ('unsafe_condition','unsafe_action','system_gap','positive_observation')),
  risk_level public.risk_level not null,
  root_cause text,
  immediate_action text,
  work_stopped boolean not null default false,
  pic_id uuid not null references public.profiles(id),
  verifier_id uuid not null references public.profiles(id),
  target_close_at timestamptz not null,
  status public.finding_status not null default 'open',
  closed_at timestamptz,
  closed_by uuid references public.profiles(id),
  residual_risk public.risk_level,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.corrective_actions (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references public.findings(id) on delete cascade,
  description text not null,
  control_hierarchy text not null check(control_hierarchy in ('elimination','substitution','engineering','administrative','ppe')),
  owner_id uuid not null references public.profiles(id),
  due_at timestamptz not null,
  progress smallint not null default 0 check(progress between 0 and 100),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check(entity_type in ('inspection','response','finding','action','closure')),
  entity_id uuid not null,
  bucket text not null default 'inspection-evidence',
  object_path text not null,
  file_name text not null,
  mime_type text,
  file_size bigint,
  uploaded_by uuid not null references public.profiles(id),
  uploaded_at timestamptz not null default now()
);
create table public.closure_requests (
  id uuid primary key default gen_random_uuid(),
  finding_id uuid not null references public.findings(id) on delete cascade,
  requested_by uuid not null references public.profiles(id),
  requested_at timestamptz not null default now(),
  closure_note text not null,
  effectiveness_note text,
  residual_risk public.risk_level,
  decision text not null default 'pending' check(decision in ('pending','approved','rejected')),
  decided_by uuid references public.profiles(id),
  decided_at timestamptz,
  rejection_reason text
);
create table public.inspection_approvals (
  id uuid primary key default gen_random_uuid(),
  inspection_id uuid not null references public.inspections(id) on delete cascade,
  stage text not null check(stage in ('plan','report','final_closing','reopen')),
  decision text not null check(decision in ('approved','rejected','reopened')),
  decided_by uuid not null references public.profiles(id),
  note text,
  decided_at timestamptz not null default now()
);
create table public.audit_logs (
  id bigint generated always as identity primary key,
  entity_type text not null,
  entity_id uuid not null,
  action text not null,
  old_data jsonb,
  new_data jsonb,
  actor_id uuid references public.profiles(id),
  reason text,
  created_at timestamptz not null default now()
);
create index inspections_status_due_idx on public.inspections(status,closing_due_at);
create index findings_status_due_idx on public.findings(status,target_close_at);
create index findings_pic_idx on public.findings(pic_id,status);
create index closure_pending_idx on public.closure_requests(decision,requested_at);

create or replace function public.current_role() returns public.app_role language sql stable security definer set search_path=public as $$ select role from public.profiles where id=auth.uid() $$;
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at();
create trigger inspections_updated before update on public.inspections for each row execute function public.set_updated_at();
create trigger findings_updated before update on public.findings for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.areas enable row level security;
alter table public.inspection_objects enable row level security;
alter table public.checklist_templates enable row level security;
alter table public.checklist_items enable row level security;
alter table public.inspections enable row level security;
alter table public.inspection_responses enable row level security;
alter table public.findings enable row level security;
alter table public.corrective_actions enable row level security;
alter table public.attachments enable row level security;
alter table public.closure_requests enable row level security;
alter table public.inspection_approvals enable row level security;
alter table public.audit_logs enable row level security;

create policy "authenticated profiles read" on public.profiles for select to authenticated using(true);
create policy "authenticated reference read" on public.areas for select to authenticated using(true);
create policy "authenticated objects read" on public.inspection_objects for select to authenticated using(true);
create policy "authenticated templates read" on public.checklist_templates for select to authenticated using(true);
create policy "authenticated items read" on public.checklist_items for select to authenticated using(true);
create policy "authenticated inspections read" on public.inspections for select to authenticated using(true);
create policy "authorized inspection create" on public.inspections for insert to authenticated with check(public.current_role() in ('admin','ktt_ptl','inspector') and created_by=auth.uid());
create policy "authorized inspection update" on public.inspections for update to authenticated using(public.current_role() in ('admin','ktt_ptl','inspector')) with check(public.current_role() in ('admin','ktt_ptl','inspector'));
create policy "authenticated responses read" on public.inspection_responses for select to authenticated using(true);
create policy "inspector responses write" on public.inspection_responses for all to authenticated using(public.current_role() in ('admin','inspector')) with check(public.current_role() in ('admin','inspector'));
create policy "authenticated findings read" on public.findings for select to authenticated using(true);
create policy "authorized findings create" on public.findings for insert to authenticated with check(public.current_role() in ('admin','ktt_ptl','inspector'));
create policy "finding participants update" on public.findings for update to authenticated using(public.current_role() in ('admin','ktt_ptl','inspector','verifier') or pic_id=auth.uid()) with check(public.current_role() in ('admin','ktt_ptl','inspector','verifier') or pic_id=auth.uid());
create policy "authenticated actions read" on public.corrective_actions for select to authenticated using(true);
create policy "action owner update" on public.corrective_actions for update to authenticated using(owner_id=auth.uid() or public.current_role() in ('admin','ktt_ptl','inspector')) with check(owner_id=auth.uid() or public.current_role() in ('admin','ktt_ptl','inspector'));
create policy "closure read" on public.closure_requests for select to authenticated using(true);
create policy "closure request create" on public.closure_requests for insert to authenticated with check(requested_by=auth.uid() and public.current_role() in ('admin','inspector','pic'));
create policy "closure verifier decision" on public.closure_requests for update to authenticated using(public.current_role() in ('admin','ktt_ptl','verifier')) with check(public.current_role() in ('admin','ktt_ptl','verifier'));
create policy "approvals read" on public.inspection_approvals for select to authenticated using(true);
create policy "final approval" on public.inspection_approvals for insert to authenticated with check(public.current_role() in ('admin','ktt_ptl') and decided_by=auth.uid());
create policy "audit read restricted" on public.audit_logs for select to authenticated using(public.current_role() in ('admin','ktt_ptl','viewer'));
-- Add storage bucket policies after creating private bucket `inspection-evidence`.
-- Production recommendation: perform final close/reopen via SECURITY DEFINER RPC
-- that validates all findings are closed, writes approval + audit log atomically.
