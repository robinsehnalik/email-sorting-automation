-- ========================================================================
-- Streamlined Email Processing Telemetry & Audit Schema
-- ========================================================================

CREATE TABLE IF NOT EXISTS email_processing_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id TEXT UNIQUE NOT NULL, -- Enforces idempotency
  thread_id TEXT,
  sender_email TEXT,
  subject TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'sales', 'bills_verified', 'bills_unverified', 'returns', 'questions',
    'newsletter', 'auth_warning', 'other', 'error'
  )),
  confidence NUMERIC(4, 3) DEFAULT 1.0,
  pre_filtered BOOLEAN DEFAULT false,
  draft_created BOOLEAN DEFAULT false,
  execution_time_ms INTEGER DEFAULT 0,
  prompt_tokens INTEGER DEFAULT 0,
  completion_tokens INTEGER DEFAULT 0,
  status TEXT DEFAULT 'processed' CHECK (status IN ('processed', 'routed', 'draft_created', 'failed')),
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Operational indexes for latency and cost tracking
CREATE INDEX IF NOT EXISTS idx_email_logs_message_id ON email_processing_logs(message_id);
CREATE INDEX IF NOT EXISTS idx_email_logs_category ON email_processing_logs(category);
CREATE INDEX IF NOT EXISTS idx_email_logs_created_at ON email_processing_logs(created_at DESC);

-- Automated 90-day telemetry retention cleanup
CREATE OR REPLACE FUNCTION purge_expired_email_logs()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM email_processing_logs WHERE created_at < now() - INTERVAL '90 days';
END;
$$;
