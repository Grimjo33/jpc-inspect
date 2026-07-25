-- Personnel assignment and role-separated workflow
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='findings_independent_verifier_check') THEN
    ALTER TABLE public.findings ADD CONSTRAINT findings_independent_verifier_check CHECK (pic_id IS NULL OR verifier_id IS NULL OR pic_id<>verifier_id) NOT VALID;
  END IF;
END $$;
-- Canonical functions are deployed in the Supabase migration named personnel_assignment_and_role_workflow:
-- public.create_assigned_inspection(...)
-- public.assign_finding_responsibility(...)
-- public.save_finding_action(...)
