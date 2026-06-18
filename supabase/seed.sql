-- Demo org + default pipeline + legacy org roles (Manager, Sales, CS, Engineer)
-- Admin chip from old UI = platform admin — not org_role

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

  PERFORM public.seed_org_role_templates(v_org_id);

  IF NOT EXISTS (
    SELECT 1 FROM public.lead_sources
    WHERE org_id = v_org_id AND deleted_at IS NULL
  ) THEN
    INSERT INTO public.lead_sources (org_id, source_code, name, sort_order, status) VALUES
      (v_org_id, 'WEB', 'เว็บไซต์', 1, 'active'),
      (v_org_id, 'GOOGLE', 'Google (Search / Ads)', 2, 'active'),
      (v_org_id, 'FACEBOOK', 'Facebook', 3, 'active'),
      (v_org_id, 'LINE', 'LINE OA', 4, 'active'),
      (v_org_id, 'INSTAGRAM', 'Instagram', 5, 'active'),
      (v_org_id, 'TIKTOK', 'TikTok', 6, 'active'),
      (v_org_id, 'REFERRAL', 'ลูกค้าแนะนำ', 7, 'active'),
      (v_org_id, 'PARTNER', 'พันธมิตร / ช่องทางคู่ค้า', 8, 'active'),
      (v_org_id, 'EVENT', 'งานแสดงสินค้า / สัมมนา', 9, 'active'),
      (v_org_id, 'WALKIN', 'หน้าร้าน / Walk-in', 10, 'active'),
      (v_org_id, 'PHONE', 'โทรเข้า', 11, 'active'),
      (v_org_id, 'EMAIL', 'อีเมลสอบถาม', 12, 'active'),
      (v_org_id, 'OTHER', 'อื่น ๆ', 13, 'active');
  END IF;
END $$;
