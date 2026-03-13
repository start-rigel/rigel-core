CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'part_category') THEN
        CREATE TYPE part_category AS ENUM ('CPU', 'MB', 'GPU', 'RAM', 'SSD', 'HDD', 'PSU', 'CASE', 'COOLER');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'source_platform') THEN
        CREATE TYPE source_platform AS ENUM ('jd', 'xianyu');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'shop_type') THEN
        CREATE TYPE shop_type AS ENUM ('self_operated', 'flagship', 'authorized', 'marketplace', 'personal', 'unknown');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'mapping_status') THEN
        CREATE TYPE mapping_status AS ENUM ('pending', 'mapped', 'rejected', 'manual_review');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_level') THEN
        CREATE TYPE risk_level AS ENUM ('info', 'warn', 'high', 'blocked');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'build_mode') THEN
        CREATE TYPE build_mode AS ENUM ('new_only', 'used_only', 'mixed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'use_case') THEN
        CREATE TYPE use_case AS ENUM ('gaming', 'office', 'design');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'build_status') THEN
        CREATE TYPE build_status AS ENUM ('pending', 'generated', 'failed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'result_role') THEN
        CREATE TYPE result_role AS ENUM ('primary', 'alternative', 'stable', 'value');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status') THEN
        CREATE TYPE job_status AS ENUM ('queued', 'running', 'succeeded', 'failed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_type') THEN
        CREATE TYPE job_type AS ENUM ('jd_collect', 'goofish_collect', 'normalize', 'build_generate', 'market_summary');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS parts (
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

CREATE INDEX IF NOT EXISTS idx_parts_category ON parts(category);
CREATE INDEX IF NOT EXISTS idx_parts_brand_model ON parts(brand, model);

CREATE TABLE IF NOT EXISTS part_specs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
    socket TEXT,
    chipset TEXT,
    memory_type TEXT,
    memory_slots INT,
    memory_speed_max INT,
    form_factor TEXT,
    pcie_slot TEXT,
    pcie_power_pin TEXT,
    tdp_watt INT,
    gpu_length_mm INT,
    cooler_height_mm INT,
    psu_form_factor TEXT,
    wattage INT,
    capacity_gb INT,
    interface_type TEXT,
    extra JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (part_id)
);

CREATE TABLE IF NOT EXISTS products (
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

CREATE INDEX IF NOT EXISTS idx_products_platform_title ON products(source_platform, title);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);

CREATE TABLE IF NOT EXISTS product_part_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    part_id UUID REFERENCES parts(id) ON DELETE SET NULL,
    mapping_status mapping_status NOT NULL DEFAULT 'pending',
    match_confidence NUMERIC(4,3) NOT NULL DEFAULT 0.000,
    matched_by TEXT NOT NULL DEFAULT 'rule',
    candidate_display_name TEXT,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (product_id)
);

CREATE INDEX IF NOT EXISTS idx_product_part_mapping_part_id ON product_part_mapping(part_id);
CREATE INDEX IF NOT EXISTS idx_product_part_mapping_status ON product_part_mapping(mapping_status);

CREATE TABLE IF NOT EXISTS price_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    part_id UUID REFERENCES parts(id) ON DELETE SET NULL,
    source_platform source_platform NOT NULL,
    price NUMERIC(12,2) NOT NULL,
    in_stock BOOLEAN NOT NULL DEFAULT TRUE,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_price_snapshots_product_time ON price_snapshots(product_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_price_snapshots_part_time ON price_snapshots(part_id, captured_at DESC);

CREATE TABLE IF NOT EXISTS part_market_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_id UUID NOT NULL REFERENCES parts(id) ON DELETE CASCADE,
    source_platform source_platform NOT NULL,
    latest_price NUMERIC(12,2),
    min_price NUMERIC(12,2),
    max_price NUMERIC(12,2),
    median_price NUMERIC(12,2),
    p25_price NUMERIC(12,2),
    p75_price NUMERIC(12,2),
    sample_count INT NOT NULL DEFAULT 0,
    window_days INT NOT NULL DEFAULT 30,
    last_collected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (part_id, source_platform, window_days)
);

CREATE INDEX IF NOT EXISTS idx_part_market_summary_platform ON part_market_summary(source_platform);

CREATE TABLE IF NOT EXISTS compatibility_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category_a part_category NOT NULL,
    category_b part_category NOT NULL,
    operator TEXT NOT NULL,
    left_field TEXT NOT NULL,
    right_field TEXT NOT NULL,
    expected_value TEXT,
    priority INT NOT NULL DEFAULT 100,
    severity risk_level NOT NULL DEFAULT 'warn',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    use_case use_case,
    message_template TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_compatibility_rules_categories ON compatibility_rules(category_a, category_b);
CREATE INDEX IF NOT EXISTS idx_compatibility_rules_active ON compatibility_rules(is_active, priority);

CREATE TABLE IF NOT EXISTS scoring_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    use_case use_case NOT NULL,
    build_mode build_mode NOT NULL,
    weights JSONB NOT NULL DEFAULT '{}'::jsonb,
    budget_strategy JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_scoring_profiles_default ON scoring_profiles(use_case, build_mode)
WHERE is_default = TRUE;

CREATE TABLE IF NOT EXISTS risk_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    part_id UUID REFERENCES parts(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    source_platform source_platform,
    risk_type TEXT NOT NULL,
    risk_level risk_level NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    evidence JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (part_id IS NOT NULL OR product_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_risk_tags_part_id ON risk_tags(part_id);
CREATE INDEX IF NOT EXISTS idx_risk_tags_product_id ON risk_tags(product_id);
CREATE INDEX IF NOT EXISTS idx_risk_tags_level ON risk_tags(risk_level);

CREATE TABLE IF NOT EXISTS build_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_no TEXT NOT NULL UNIQUE,
    budget NUMERIC(12,2) NOT NULL,
    use_case use_case NOT NULL,
    build_mode build_mode NOT NULL,
    pinned_part_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    constraints JSONB NOT NULL DEFAULT '{}'::jsonb,
    status build_status NOT NULL DEFAULT 'pending',
    requested_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_build_requests_status ON build_requests(status);
CREATE INDEX IF NOT EXISTS idx_build_requests_use_case ON build_requests(use_case, build_mode);

CREATE TABLE IF NOT EXISTS build_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    build_request_id UUID NOT NULL REFERENCES build_requests(id) ON DELETE CASCADE,
    result_role result_role NOT NULL,
    scoring_profile_id UUID REFERENCES scoring_profiles(id) ON DELETE SET NULL,
    total_price NUMERIC(12,2) NOT NULL,
    score NUMERIC(8,3) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'CNY',
    summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    explanation_seed JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_build_results_request_id ON build_results(build_request_id, result_role);

CREATE TABLE IF NOT EXISTS build_result_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    build_result_id UUID NOT NULL REFERENCES build_results(id) ON DELETE CASCADE,
    part_id UUID REFERENCES parts(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    category part_category NOT NULL,
    display_name TEXT NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    source_platform source_platform,
    is_primary BOOLEAN NOT NULL DEFAULT TRUE,
    reasons JSONB NOT NULL DEFAULT '[]'::jsonb,
    risks JSONB NOT NULL DEFAULT '[]'::jsonb,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_build_result_items_result_id ON build_result_items(build_result_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_build_result_items_part_id ON build_result_items(part_id);

CREATE TABLE IF NOT EXISTS jobs (
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

CREATE INDEX IF NOT EXISTS idx_jobs_status_type ON jobs(status, job_type);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled_at ON jobs(scheduled_at);
