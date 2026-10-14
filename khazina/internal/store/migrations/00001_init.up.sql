CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- ORGANIZATIONS & PROJECTS
-- ============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),

    name VARCHAR(100) NOT NULL,
    environment VARCHAR(20) NOT NULL DEFAULT 'sandbox', -- sandbox, production
    custom_domain VARCHAR(255) UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    UNIQUE (organization_id, environment)
);

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- DASHBOARD USERS & AUTH
-- ============================================================================

CREATE TABLE customer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE customer_session (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,

    current_jti_hash BYTEA NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE auth_intent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email VARCHAR(320) UNIQUE NOT NULL,
    token_hash BYTEA UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TYPE organization_role AS ENUM ('owner', 'admin', 'member');

CREATE TABLE organization_customer (
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customer(id) ON DELETE CASCADE,

    role organization_role NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (organization_id, customer_id)
);

-- ============================================================================
-- GATEWAY ACCOUNTS
-- ============================================================================

CREATE TABLE gateway_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),

    connector_type VARCHAR(50) NOT NULL, -- mpgs
    account_name VARCHAR(100) NOT NULL,

    -- public info (base_url, merchant_id)
    config JSONB NOT NULL DEFAULT '{}',
    -- encrypted private info (api_password)
    secret BYTEA NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_gateway_accounts_updated_at BEFORE UPDATE ON gateway_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INVOICES
-- ============================================================================

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),

    amount_minor BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'BHD',

    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- pending, paid, cancelled

    external_id VARCHAR(100),
    customer_email VARCHAR(255),
    customer_name VARCHAR(100),
    description TEXT,

    paid_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    UNIQUE (project_id, external_id),
    CONSTRAINT paid_invoices_have_paid_at CHECK (status != 'paid' OR paid_at IS NOT NULL)
);

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id),

    name VARCHAR(255) NOT NULL,
    description TEXT,

    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price_minor BIGINT NOT NULL,
    amount_minor BIGINT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- PAYMENT INTENTS
-- ============================================================================

CREATE TABLE payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    project_id UUID NOT NULL REFERENCES projects(id),
    gateway_account_id UUID NOT NULL REFERENCES gateway_accounts(id),

    amount_minor BIGINT NOT NULL,
    currency VARCHAR(3) NOT NULL,

    -- created, ready_to_authenticate, awaiting_authentication_result,
    -- ready_to_capture, capturing, succeeded, failed
    status VARCHAR(30) NOT NULL DEFAULT 'created',
    payment_method VARCHAR(30) NOT NULL DEFAULT 'card', -- card, apple_pay

    -- gateway-side setup handle, e.g. the MPGS session id
    gateway_setup_reference VARCHAR(100),

    payer_ip VARCHAR(50) NOT NULL,
    payer_user_agent TEXT NOT NULL,

    idempotency_key VARCHAR(64) NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 minutes'),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_payment_intents_idempotency_key
    ON payment_intents (invoice_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL;

CREATE TRIGGER update_payment_intents_updated_at BEFORE UPDATE ON payment_intents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- GATEWAY OPERATIONS
-- ============================================================================

CREATE TABLE gateway_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_intent_id UUID NOT NULL REFERENCES payment_intents(id),
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    project_id UUID NOT NULL REFERENCES projects(id),
    gateway_account_id UUID NOT NULL REFERENCES gateway_accounts(id),

    -- prepare_card_authentication, authenticate_cardholder,
    -- get_card_authentication_result, capture_payment
    operation_type VARCHAR(30) NOT NULL,
    gateway_reference VARCHAR(100) NOT NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'pending', -- pending, completed, errored

    raw_request JSONB,
    raw_response JSONB,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_gateway_operations_updated_at BEFORE UPDATE ON gateway_operations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
