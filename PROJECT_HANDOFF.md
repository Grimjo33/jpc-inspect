# JPC Inspect — AI Project Handoff

Last updated: 2026-07-25 (Asia/Bangkok)

## How to continue in a new chat

Tell the assistant:

> Continue development of JPC Inspect. Read `PROJECT_HANDOFF.md` in `Grimjo33/jpc-inspect`, inspect the latest code and Supabase schema before changing anything, then continue from the Next Priority section. Do not recreate completed work.

## Project

- Product: planned mining inspection workflow for PT Jambi Prima Coal.
- Repository: `Grimjo33/jpc-inspect`, branch `main`.
- Production: `https://k3.jpc.web.id/`
- Vercel deployment: `https://jpc-inspect-pohu.vercel.app/`
- Supabase project reference: `pmebvfomujjhscwlauyc`.
- Supabase Storage bucket: `inspection-evidence` (private; JPEG/PNG/PDF, max 10 MB).
- Never commit or repeat Supabase secret/service-role keys. A legacy public anon key appeared in an earlier chat; do not quote it.

## Latest known commits

- `21af8dfc7395c596e953eafa12002198f5227d0e` — fixed and loaded Team & Access module.
- `a4491a179ecb9e64e1d18923130df08ad0fea73b` — role assignments and personal queues.
- `341e722706ac23db06ec278e81ae55bd2b6cb937` — synchronized follow-up actions into reports.
- `96270f1303afc4870af49963f2725b4b25f612e5` — final UI polish.

Always inspect the latest `main` commit because newer commits may exist.

## Current user state

- One active profile currently exists.
- Profile ID: `8f70064c-0693-471f-bb5d-bfd126351925`.
- Name: Rahmat Wira Dafitra.
- Role: `admin`.
- Department: Engineering.
- Role-separated UAT is blocked until at least a distinct PIC and Verifier account are registered.

## Completed architecture

### Core application

- Vercel frontend/API and Supabase database are operational.
- Authentication, explicit `.html` routing, dashboard, premium navigation, motion, loading states, green success checks, and activity toasts are implemented.
- Main dashboard loads `v3.html` in an iframe and sequentially injects workflow modules.

### Inspection lifecycle

1. Registration and personnel assignment.
2. Field checklist.
3. Follow-up/corrective action.
4. Formal report.
5. Approval and final PDF.

The visible standalone Findings Follow-up sidebar menu was removed; findings are integrated into `Inspeksi & Alur`.

### Findings and closing

- Checklist submission is atomic and automatically creates findings for nonconforming responses.
- Immediate action, permanent action, root cause, progress, evidence, closure request, independent verification, rejection/reopening, and final closing exist.
- PIC cannot verify their own work.
- Evidence is stored in the private Supabase bucket; browser images are resized to max 1600 px/JPEG quality 0.78.

### Formal reports

- Tables: `inspection_reports`, `inspection_report_approvals`.
- Signed checklist attachment, draft, submit, AMN/KTT/SHE acknowledgement, final status, snapshot, and authenticated PDF endpoint exist.
- Sequential report number format: `NNNN/INS/JPC/MM/YYYY` using `inspection_report_no_seq`.
- Follow-up mapping is automatic for draft reports:
  - Initial action -> Direct action.
  - Permanent action -> Follow-up action.
- Submitted/final reports retain their historical snapshot.

### Personnel assignment — latest phase

Backend now includes secure assignment RPCs and audit logging:

- `create_assigned_inspection(...)`
- `assign_finding_participants(...)`
- `admin_update_profile_role(...)`

Rules:

- Inspector and final approver are selected when creating an inspection.
- Findings may remain unassigned until an authorized user assigns PIC and Verifier.
- PIC and Verifier must be active, role-eligible, and different users.
- Target closing is mandatory.
- Existing findings whose PIC and Verifier were the same had the Verifier cleared for safe reassignment.
- New identical automatic assignments are normalized to unassigned.
- Personal dashboard queues show Inspector, PIC, Verifier, and approval work.
- Admin-only `Tim & Akses` UI manages profile role and active status.
- Admin cannot demote or deactivate their own account.

## Important frontend files

- `dashboard.html`
- `v3.html`, `v3.css`
- `data/v3.js`
- `data/supabase.js`
- `data/checklist.js`
- `data/workflow-v2.js`
- `data/workflow-feedback-v2.js`
- `data/report-workflow-v2.js`
- `data/app-final.js`
- `data/integrated-flow.js`
- `data/ui-final-polish.js`
- `data/report-action-sync.js`
- `data/role-assignment.js`
- `data/team-admin.js`

Current dashboard module order ends with:

1. `report-action-sync.js`
2. `role-assignment.js`
3. `team-admin.js`

Do not introduce observers that rewrite content they observe; previous infinite render loops were fixed in `app-final.js` and `integrated-flow.js`.

## Important backend objects

Core tables include:

- `profiles`, `areas`, `inspection_objects`, `checklist_templates`, `checklist_items`
- `inspections`, `inspection_responses`, `findings`, `corrective_actions`
- `attachments`, `closure_requests`, `inspection_approvals`, `audit_logs`
- `inspection_reports`, `inspection_report_approvals`

Role enum values:

- `admin`, `ktt_ptl`, `inspector`, `pic`, `verifier`, `viewer`

Important finding RPCs:

- `submit_inspection_checklist`
- `save_finding_immediate_action`
- `save_finding_action`
- `register_finding_evidence`
- `request_finding_closure`
- `decide_finding_closure`
- `final_close_finding`

Important report RPCs:

- `save_inspection_report_draft`
- `register_inspection_document`
- `submit_inspection_report`
- `acknowledge_inspection_report`

## Known cautions

- Verify all latest database function definitions before modifying them; multiple earlier overloads may exist for `create_assigned_inspection`.
- The repository migration file for the latest personnel phase is descriptive and may not contain every exact deployed function body. Inspect deployed Supabase functions before consolidating migrations.
- Supabase security advisor still warns about exposed `SECURITY DEFINER` RPCs and leaked-password protection being disabled. The RPCs contain internal authorization checks, but they require a dedicated security review.
- Performance advisor previously reported missing report foreign-key indexes and a duplicate `inspection_responses` index.
- Do not claim production readiness before role-separated UAT, PDF verification, deployment verification, and security hardening.

## Next priority

1. Wait for/verify the latest Vercel deployment and hard-refresh the production dashboard.
2. Register at least two additional accounts through `login.html`: one PIC and one Verifier.
3. In Admin -> `Tim & Akses`, refresh profiles and assign the distinct roles.
4. Run full role-separated UAT:
   - Admin creates assigned inspection.
   - Inspector completes checklist.
   - Admin/Inspector assigns PIC, Verifier, and target closing.
   - PIC records actions and evidence, then requests closing.
   - Assigned Verifier independently accepts/rejects.
   - Authorized role performs final closing.
   - Inspector submits report; AMN/KTT/SHE approve; final PDF is verified.
5. Fix any issues found during UAT.
6. Then improve report rejection/revision, final PDF design, attachment preview/replace/remove, migration consolidation, indexes, and security hardening.

## Regulations already used as design references

- Permen ESDM No. 26 Tahun 2018.
- Kepmen ESDM No. 1827 K/30/MEM/2018.
- Kepdirjen Minerba No. 185.K/37.04/DJB/2019.

This application supports compliance workflow but must still be validated by the organization’s KTT/PTL/SHE and legal/compliance stakeholders before formal production use.
