-- Role assignment and separation of duties
ALTER TABLE public.findings ALTER COLUMN pic_id DROP NOT NULL;
ALTER TABLE public.findings ALTER COLUMN verifier_id DROP NOT NULL;
UPDATE public.findings SET verifier_id=NULL WHERE verifier_id=pic_id;
-- Deployed functions:
-- create_assigned_inspection: validates creator, inspector, final approver, dates, and audit trail.
-- assign_finding_participants: validates active PIC and Verifier, prevents self-verification, and records audit trail.
-- New findings with identical initial PIC/Verifier are normalized to unassigned until an authorized person assigns both roles.
