CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TYPES
-- ============================================================================

CREATE TYPE environment AS ENUM ('sandbox', 'production');
CREATE TYPE organization_role AS ENUM ('owner', 'admin', 'member');
CREATE TYPE gateway_type AS ENUM ('mpgs');
CREATE TYPE payment_intent_status AS ENUM (
    'requires_payment_method',
    'requires_action',
    'processing',
    'succeeded',
    'canceled'
);
CREATE TYPE checkout_session_status AS ENUM ('open', 'complete', 'expired', 'canceled');
CREATE TYPE payment_method_type AS ENUM ('card', 'apple_pay');
CREATE TYPE payment_attempt_status AS ENUM (
    'created',
    'requires_action',
    'processing',
    'capturing',
    'succeeded',
    'failed',
    'expired',
    'canceled'
);
CREATE TYPE payment_intent_cancellation_reason AS ENUM ('merchant_canceled', 'abandoned');
CREATE TYPE payment_attempt_cancellation_reason AS ENUM ('superseded', 'merchant_canceled', 'customer_canceled');
CREATE TYPE authentication_method AS ENUM ('three_d_secure', 'device', 'none');
CREATE TYPE authentication_status AS ENUM ('authenticated', 'attempted', 'failed', 'unavailable');

-- ============================================================================
-- ORGANIZATIONS & ACCOUNTS
-- ============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES organizations(id),

    name VARCHAR(100) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- DASHBOARD USERS & AUTH
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(100) NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    current_jti_hash BYTEA NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE auth_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    email VARCHAR(320) UNIQUE NOT NULL,
    token_hash BYTEA UNIQUE NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE organization_members (
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    role organization_role NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (organization_id, user_id)
);

-- ============================================================================
-- GATEWAYS
-- ============================================================================

CREATE TABLE gateways (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id),
    environment environment NOT NULL,

    type gateway_type NOT NULL,
    name VARCHAR(100) NOT NULL,

    -- What the merchant entered (for MPGS: host and merchant id); fixed once created.
    config JSONB NOT NULL DEFAULT '{}',
    secret BYTEA NOT NULL,
    -- What verification discovered from the gateway (card brands, currencies).
    capabilities JSONB NOT NULL DEFAULT '{}',
    capabilities_checked_at TIMESTAMPTZ,

    is_active BOOLEAN NOT NULL DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,

    CHECK (NOT is_active OR capabilities_checked_at IS NOT NULL),

    UNIQUE (id, account_id, environment)
);

CREATE UNIQUE INDEX idx_gateways_one_active ON gateways (account_id, environment)
    WHERE is_active AND deleted_at IS NULL;

-- ============================================================================
-- PAYMENT INTENTS
-- ============================================================================

CREATE TABLE payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id),
    environment environment NOT NULL,

    amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
    currency VARCHAR(3) NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),

    status payment_intent_status NOT NULL DEFAULT 'requires_payment_method',
    cancellation_reason payment_intent_cancellation_reason,

    description TEXT,
    external_id VARCHAR(255),

    succeeded_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (status != 'succeeded' OR succeeded_at IS NOT NULL),
    CHECK (status != 'canceled' OR canceled_at IS NOT NULL),
    CHECK ((status = 'canceled') = (cancellation_reason IS NOT NULL)),

    UNIQUE (id, account_id, environment)
);

CREATE INDEX idx_payment_intents_external_id ON payment_intents (account_id, environment, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_payment_intents_list ON payment_intents (account_id, environment, created_at DESC);

-- ============================================================================
-- PAYMENT LINKS
-- ============================================================================

CREATE TABLE payment_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(id),
    environment environment NOT NULL,

    amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
    currency VARCHAR(3) NOT NULL CHECK (currency ~ '^[A-Z]{3}$'),
    description TEXT NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- NULL means unlimited. Payments are counted under a lock on this row when a capture starts.
    max_payments INT CHECK (max_payments > 0),
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (id, account_id, environment)
);

-- ============================================================================
-- CHECKOUT SESSIONS
-- ============================================================================

CREATE TABLE checkout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL,
    environment environment NOT NULL,
    payment_intent_id UUID NOT NULL UNIQUE,
    payment_link_id UUID,

    status checkout_session_status NOT NULL DEFAULT 'open',

    customer_email VARCHAR(320),
    customer_name VARCHAR(100),

    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
    completed_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK (status != 'complete' OR completed_at IS NOT NULL),
    CHECK (status != 'canceled' OR canceled_at IS NOT NULL),

    FOREIGN KEY (payment_intent_id, account_id, environment)
        REFERENCES payment_intents(id, account_id, environment),
    FOREIGN KEY (payment_link_id, account_id, environment)
        REFERENCES payment_links(id, account_id, environment)
);

CREATE INDEX idx_checkout_sessions_payment_link ON checkout_sessions (payment_link_id)
    WHERE payment_link_id IS NOT NULL;

-- ============================================================================
-- PAYMENT ATTEMPTS
-- ============================================================================

CREATE TABLE payment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL,
    environment environment NOT NULL,
    payment_intent_id UUID NOT NULL,
    gateway_id UUID NOT NULL,

    -- An attempt always charges its intent's amount and currency.
    payment_method_type payment_method_type NOT NULL,
    status payment_attempt_status NOT NULL DEFAULT 'created',
    cancellation_reason payment_attempt_cancellation_reason,

    -- The gateway order id is this attempt's id; gateway_data is the adapter's private state.
    gateway_data JSONB NOT NULL DEFAULT '{"v": 1}',
    -- What the customer must do now while requires_action; safe to send to the browser.
    next_action JSONB,
    -- What we show for this method, normalized by the adapter: card brand, last 4, ...
    payment_method_details JSONB,

    authentication_method authentication_method,
    authentication_status authentication_status,
    eci VARCHAR(2),
    liability_shift BOOLEAN,

    failure_code VARCHAR(50),

    payer_ip VARCHAR(50) NOT NULL,
    payer_user_agent TEXT NOT NULL,

    idempotency_key VARCHAR(64) NOT NULL,

    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '15 minutes'),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CHECK ((status = 'canceled') = (cancellation_reason IS NOT NULL)),

    UNIQUE (account_id, environment, idempotency_key),
    UNIQUE (id, account_id, environment),
    UNIQUE (id, payment_intent_id),
    FOREIGN KEY (payment_intent_id, account_id, environment)
        REFERENCES payment_intents(id, account_id, environment),
    FOREIGN KEY (gateway_id, account_id, environment)
        REFERENCES gateways(id, account_id, environment)
);

CREATE INDEX idx_payment_attempts_payment_intent ON payment_attempts (payment_intent_id);

CREATE UNIQUE INDEX idx_payment_attempts_one_capture_per_intent ON payment_attempts (payment_intent_id)
    WHERE status IN ('capturing', 'succeeded');

CREATE INDEX idx_payment_attempts_capturing ON payment_attempts (updated_at)
    WHERE status = 'capturing';

-- ============================================================================
-- GATEWAY REQUESTS
-- ============================================================================

-- Every HTTP call to a gateway, recorded by the adapters' HTTP transport. A log for
-- people and disputes; payment logic never reads it.
CREATE TABLE gateway_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL,
    environment environment NOT NULL,
    gateway_id UUID NOT NULL,
    payment_intent_id UUID,
    payment_attempt_id UUID,

    method VARCHAR(10) NOT NULL,
    url TEXT NOT NULL,
    request_body JSONB,
    response_body JSONB,
    -- NULL when no response came back; error says why.
    http_status SMALLINT,
    error TEXT,

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    finished_at TIMESTAMPTZ,

    CHECK (payment_attempt_id IS NULL OR payment_intent_id IS NOT NULL),

    FOREIGN KEY (gateway_id, account_id, environment)
        REFERENCES gateways(id, account_id, environment),
    FOREIGN KEY (payment_intent_id, account_id, environment)
        REFERENCES payment_intents(id, account_id, environment),
    FOREIGN KEY (payment_attempt_id, payment_intent_id)
        REFERENCES payment_attempts(id, payment_intent_id)
);

CREATE INDEX idx_gateway_requests_payment_intent ON gateway_requests (payment_intent_id, started_at)
    WHERE payment_intent_id IS NOT NULL;
CREATE INDEX idx_gateway_requests_gateway ON gateway_requests (gateway_id, started_at);
