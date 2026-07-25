-- Team & Access now stores authority roles only: user, verifier, KTT/PTL, and admin.
-- Operational Inspector and PIC responsibilities are assigned per inspection/finding.
update public.profiles set role='viewer'::public.app_role,updated_at=now() where role in ('inspector'::public.app_role,'pic'::public.app_role);
-- Deployed migration simplify_team_access_roles also updates admin_update_profile_role
-- to reject inspector/pic as account roles while preserving self-demotion protection and audit logging.
