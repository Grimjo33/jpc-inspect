-- Personnel assignment and separation of duties
ALTER TABLE public.findings ALTER COLUMN pic_id DROP NOT NULL;
ALTER TABLE public.findings ALTER COLUMN verifier_id DROP NOT NULL;
UPDATE public.findings SET verifier_id = NULL WHERE pic_id = verifier_id;
ALTER TABLE public.findings ADD CONSTRAINT findings_pic_verifier_distinct CHECK (pic_id IS NULL OR verifier_id IS NULL OR pic_id <> verifier_id);
-- RPC assign_finding_participants validates active roles, distinct PIC/verifier, target closing, authorization, and writes audit_logs.
-- save_finding_action now requires an assigned PIC; only that PIC or Admin/KTT override may update permanent actions.
