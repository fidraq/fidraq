DROP TABLE IF EXISTS gateway_operations;
DROP TABLE IF EXISTS payment_intents;
DROP TABLE IF EXISTS invoice_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS gateway_accounts;
DROP TABLE IF EXISTS organization_customer;
DROP TYPE IF EXISTS organization_role;
DROP TABLE IF EXISTS auth_intent;
DROP TABLE IF EXISTS customer_session;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS organizations;

DROP FUNCTION IF EXISTS update_updated_at_column();

DROP EXTENSION IF EXISTS "pgcrypto";
