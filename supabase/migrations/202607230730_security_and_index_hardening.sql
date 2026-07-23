create or replace function public.current_role()
returns public.app_role language sql stable security invoker set search_path = public
as $$ select role from public.profiles where id = (select auth.uid()) $$;

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker set search_path = public
as $$ begin new.updated_at = now(); return new; end $$;

create policy "authenticated attachments read" on public.attachments for select to authenticated using (true);
create policy "authenticated attachments create" on public.attachments for insert to authenticated with check (uploaded_by = (select auth.uid()));
create policy "attachment owner or admin delete" on public.attachments for delete to authenticated using (uploaded_by = (select auth.uid()) or public.current_role() = 'admin');

drop policy if exists "authorized inspection create" on public.inspections;
create policy "authorized inspection create" on public.inspections for insert to authenticated with check (public.current_role() in ('admin','ktt_ptl','inspector') and created_by = (select auth.uid()));
drop policy if exists "finding participants update" on public.findings;
create policy "finding participants update" on public.findings for update to authenticated using (public.current_role() in ('admin','ktt_ptl','inspector','verifier') or pic_id = (select auth.uid())) with check (public.current_role() in ('admin','ktt_ptl','inspector','verifier') or pic_id = (select auth.uid()));
drop policy if exists "action owner update" on public.corrective_actions;
create policy "action owner update" on public.corrective_actions for update to authenticated using (owner_id = (select auth.uid()) or public.current_role() in ('admin','ktt_ptl','inspector')) with check (owner_id = (select auth.uid()) or public.current_role() in ('admin','ktt_ptl','inspector'));
drop policy if exists "closure request create" on public.closure_requests;
create policy "closure request create" on public.closure_requests for insert to authenticated with check (requested_by = (select auth.uid()) and public.current_role() in ('admin','inspector','pic'));
drop policy if exists "final approval" on public.inspection_approvals;
create policy "final approval" on public.inspection_approvals for insert to authenticated with check (public.current_role() in ('admin','ktt_ptl') and decided_by = (select auth.uid()));
drop policy if exists "inspector responses write" on public.inspection_responses;
create policy "inspector responses insert" on public.inspection_responses for insert to authenticated with check (public.current_role() in ('admin','inspector') and answered_by = (select auth.uid()));
create policy "inspector responses update" on public.inspection_responses for update to authenticated using (public.current_role() in ('admin','inspector')) with check (public.current_role() in ('admin','inspector'));
create policy "inspector responses delete" on public.inspection_responses for delete to authenticated using (public.current_role() in ('admin','inspector'));

create index if not exists areas_owner_id_idx on public.areas(owner_id);
create index if not exists attachments_uploaded_by_idx on public.attachments(uploaded_by);
create index if not exists audit_logs_actor_id_idx on public.audit_logs(actor_id);
create index if not exists checklist_templates_approved_by_idx on public.checklist_templates(approved_by);
create index if not exists checklist_templates_object_id_idx on public.checklist_templates(object_id);
create index if not exists closure_requests_decided_by_idx on public.closure_requests(decided_by);
create index if not exists closure_requests_finding_id_idx on public.closure_requests(finding_id);
create index if not exists closure_requests_requested_by_idx on public.closure_requests(requested_by);
create index if not exists corrective_actions_finding_id_idx on public.corrective_actions(finding_id);
create index if not exists corrective_actions_owner_id_idx on public.corrective_actions(owner_id);
create index if not exists findings_closed_by_idx on public.findings(closed_by);
create index if not exists findings_created_by_idx on public.findings(created_by);
create index if not exists findings_inspection_id_idx on public.findings(inspection_id);
create index if not exists findings_response_id_idx on public.findings(response_id);
create index if not exists findings_verifier_id_idx on public.findings(verifier_id);
create index if not exists inspection_approvals_decided_by_idx on public.inspection_approvals(decided_by);
create index if not exists inspection_approvals_inspection_id_idx on public.inspection_approvals(inspection_id);
create index if not exists inspection_objects_area_id_idx on public.inspection_objects(area_id);
create index if not exists inspection_responses_answered_by_idx on public.inspection_responses(answered_by);
create index if not exists inspection_responses_checklist_item_id_idx on public.inspection_responses(checklist_item_id);
create index if not exists inspections_closed_by_idx on public.inspections(closed_by);
create index if not exists inspections_created_by_idx on public.inspections(created_by);
create index if not exists inspections_final_approver_id_idx on public.inspections(final_approver_id);
create index if not exists inspections_inspector_id_idx on public.inspections(inspector_id);
create index if not exists inspections_object_id_idx on public.inspections(object_id);
create index if not exists inspections_template_id_idx on public.inspections(template_id);
