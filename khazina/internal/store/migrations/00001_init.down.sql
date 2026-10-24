DROP TABLE IF EXISTS gateway_requests;
DROP TABLE IF EXISTS payment_attempts;
DROP TABLE IF EXISTS checkout_sessions;
DROP TABLE IF EXISTS payment_links;
DROP TABLE IF EXISTS payment_intents;
DROP TABLE IF EXISTS gateways;
DROP TABLE IF EXISTS organization_members;
DROP TABLE IF EXISTS auth_intents;
DROP TABLE IF EXISTS user_sessions;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS organizations;

DROP TYPE IF EXISTS authentication_status;
DROP TYPE IF EXISTS authentication_method;
DROP TYPE IF EXISTS payment_attempt_cancellation_reason;
DROP TYPE IF EXISTS payment_intent_cancellation_reason;
DROP TYPE IF EXISTS payment_attempt_status;
DROP TYPE IF EXISTS payment_method_type;
DROP TYPE IF EXISTS checkout_session_status;
DROP TYPE IF EXISTS payment_intent_status;
DROP TYPE IF EXISTS gateway_type;
DROP TYPE IF EXISTS organization_role;
DROP TYPE IF EXISTS environment;

DROP EXTENSION IF EXISTS "pgcrypto";
