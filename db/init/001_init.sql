CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'part_category') THEN
        CREATE TYPE part_category AS ENUM ('CPU', 'MB', 'GPU', 'RAM', 'SSD', 'HDD', 'PSU', 'CASE', 'COOLER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'source_platform') THEN
        CREATE TYPE source_platform AS ENUM ('jd');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shop_type') THEN
        CREATE TYPE shop_type AS ENUM ('self_operated', 'flagship', 'authorized', 'marketplace', 'unknown');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'mapping_status') THEN
        CREATE TYPE mapping_status AS ENUM ('pending', 'mapped', 'rejected', 'manual_review');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status') THEN
        CREATE TYPE job_status AS ENUM ('queued', 'running', 'succeeded', 'failed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_type') THEN
        CREATE TYPE job_type AS ENUM ('jd_collect', 'market_summary', 'keyword_import');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS rigel_keyword_seeds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category part_category NOT NULL,
    keyword TEXT NOT NULL,
    canonical_model TEXT NOT NULL,
    brand TEXT,
    aliases_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    priority INT NOT NULL DEFAULT 100,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_rigel_keyword_seeds_category_keyword
    ON rigel_keyword_seeds (category, keyword);
CREATE INDEX IF NOT EXISTS idx_rigel_keyword_seeds_enabled_priority
    ON rigel_keyword_seeds (enabled, priority DESC);

CREATE TABLE IF NOT EXISTS rigel_parts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category part_category NOT NULL,
    brand TEXT NOT NULL,
    series TEXT,
    model TEXT NOT NULL,
    display_name TEXT NOT NULL,
    normalized_key TEXT NOT NULL UNIQUE,
    generation TEXT,
    msrp NUMERIC(12,2),
    release_year INT,
    lifecycle_status TEXT NOT NULL DEFAULT 'active',
    source_confidence NUMERIC(4,3) NOT NULL DEFAULT 1.000,
    alias_keywords JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rigel_parts_category ON rigel_parts(category);
CREATE INDEX IF NOT EXISTS idx_rigel_parts_brand_model ON rigel_parts(brand, model);

CREATE TABLE IF NOT EXISTS rigel_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_platform source_platform NOT NULL,
    external_id TEXT NOT NULL,
    sku_id TEXT,
    title TEXT NOT NULL,
    subtitle TEXT,
    url TEXT NOT NULL,
    image_url TEXT,
    shop_name TEXT,
    shop_type shop_type NOT NULL DEFAULT 'unknown',
    seller_name TEXT,
    region TEXT,
    price NUMERIC(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'CNY',
    availability TEXT NOT NULL DEFAULT 'unknown',
    attributes JSONB NOT NULL DEFAULT '{}'::jsonb,
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source_platform, external_id)
);

CREATE INDEX IF NOT EXISTS idx_rigel_products_platform_title ON rigel_products(source_platform, title);
CREATE INDEX IF NOT EXISTS idx_rigel_products_price ON rigel_products(price);

CREATE TABLE IF NOT EXISTS rigel_price_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES rigel_products(id) ON DELETE CASCADE,
    source_platform source_platform NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    in_stock BOOLEAN NOT NULL DEFAULT TRUE,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_rigel_price_snapshots_product_time
    ON rigel_price_snapshots(product_id, captured_at DESC);

CREATE TABLE IF NOT EXISTS rigel_product_part_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES rigel_products(id) ON DELETE CASCADE,
    part_id UUID REFERENCES rigel_parts(id) ON DELETE SET NULL,
    keyword_seed_id UUID REFERENCES rigel_keyword_seeds(id) ON DELETE SET NULL,
    mapping_status mapping_status NOT NULL DEFAULT 'pending',
    match_confidence NUMERIC(4,3) NOT NULL DEFAULT 0.000,
    matched_by TEXT NOT NULL DEFAULT 'rule',
    candidate_display_name TEXT,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (product_id)
);

CREATE INDEX IF NOT EXISTS idx_rigel_product_part_mapping_part_id
    ON rigel_product_part_mapping(part_id);
CREATE INDEX IF NOT EXISTS idx_rigel_product_part_mapping_keyword_seed_id
    ON rigel_product_part_mapping(keyword_seed_id);
CREATE INDEX IF NOT EXISTS idx_rigel_product_part_mapping_status
    ON rigel_product_part_mapping(mapping_status);

CREATE TABLE IF NOT EXISTS rigel_part_market_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_id UUID NOT NULL REFERENCES rigel_parts(id) ON DELETE CASCADE,
    source_platform source_platform NOT NULL,
    snapshot_date DATE NOT NULL,
    latest_price NUMERIC(12,2),
    min_price NUMERIC(12,2),
    max_price NUMERIC(12,2),
    median_price NUMERIC(12,2),
    p25_price NUMERIC(12,2),
    p75_price NUMERIC(12,2),
    sample_count INT NOT NULL DEFAULT 0,
    last_collected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (part_id, source_platform, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_rigel_part_market_summary_platform
    ON rigel_part_market_summary(source_platform);
CREATE INDEX IF NOT EXISTS idx_rigel_part_market_summary_snapshot_date
    ON rigel_part_market_summary(snapshot_date DESC);

CREATE TABLE IF NOT EXISTS rigel_collector_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name TEXT NOT NULL UNIQUE,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    schedule_time TEXT NOT NULL,
    request_interval_seconds INT NOT NULL DEFAULT 0,
    query_limit INT NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rigel_collector_schedules_enabled
    ON rigel_collector_schedules(enabled);

CREATE TABLE IF NOT EXISTS rigel_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type job_type NOT NULL,
    status job_status NOT NULL DEFAULT 'queued',
    source_platform source_platform,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    result JSONB NOT NULL DEFAULT '{}'::jsonb,
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    retry_count INT NOT NULL DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rigel_jobs_status_type
    ON rigel_jobs(status, job_type);
CREATE INDEX IF NOT EXISTS idx_rigel_jobs_scheduled_at
    ON rigel_jobs(scheduled_at);

CREATE TABLE IF NOT EXISTS rigel_system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT NOT NULL UNIQUE,
    value_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO rigel_system_settings (setting_key, value_json)
VALUES
    (
        'catalog_ai_limits',
        jsonb_build_object('max_models_per_category', 5)
    ),
    (
        'ai_runtime',
        jsonb_build_object(
            'base_url', '',
            'gateway_token', '',
            'api_token', '',
            'model', 'openai/gpt-5.4-nano',
            'timeout_seconds', 25,
            'enabled', true
        )
    )
ON CONFLICT (setting_key) DO NOTHING;
