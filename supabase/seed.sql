-- Demo org + default pipeline
-- Fixed UUID for reference in docs

INSERT INTO public.organizations (id, name, slug, settings)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Demo Corp',
  'demo',
  '{"currency": "THB", "timezone": "Asia/Bangkok"}'::jsonb
)
ON CONFLICT (slug) DO NOTHING;

DO $$
DECLARE
  v_org_id uuid := '11111111-1111-1111-1111-111111111111';
  v_pipeline_id uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.pipelines WHERE org_id = v_org_id AND is_default = true) THEN
    INSERT INTO public.pipelines (org_id, name, is_default, sort_order)
    VALUES (v_org_id, 'Sales', true, 0)
    RETURNING id INTO v_pipeline_id;

    INSERT INTO public.pipeline_stages (org_id, pipeline_id, name, sort_order, probability, is_won, is_lost, color) VALUES
      (v_org_id, v_pipeline_id, 'Lead', 0, 10, false, false, '#94a3b8'),
      (v_org_id, v_pipeline_id, 'Qualified', 1, 25, false, false, '#3b82f6'),
      (v_org_id, v_pipeline_id, 'Proposal', 2, 50, false, false, '#8b5cf6'),
      (v_org_id, v_pipeline_id, 'Negotiation', 3, 75, false, false, '#f59e0b'),
      (v_org_id, v_pipeline_id, 'Won', 4, 100, true, false, '#22c55e'),
      (v_org_id, v_pipeline_id, 'Lost', 5, 0, false, true, '#ef4444');
  END IF;
END $$;
