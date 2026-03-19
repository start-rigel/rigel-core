-- Recommendation integration test data (non-mock).
-- Safe to re-run.

INSERT INTO rigel_keyword_seeds (category, keyword, canonical_model, brand, aliases_json, priority, enabled, notes)
VALUES
    ('CPU', 'Ryzen 5 7500F', 'Ryzen 5 7500F', 'AMD', '["7500F"]'::jsonb, 100, true, 'seed for recommendation e2e'),
    ('GPU', 'RTX 4060', 'RTX 4060', 'NVIDIA', '["4060"]'::jsonb, 100, true, 'seed for recommendation e2e'),
    ('MB', 'B650M', 'B650M', '', '["B650"]'::jsonb, 90, true, 'seed for recommendation e2e'),
    ('RAM', 'DDR5 6000 32GB', 'DDR5 6000 32GB', '', '["32G"]'::jsonb, 90, true, 'seed for recommendation e2e'),
    ('SSD', 'PCIe4 1TB', 'PCIe4 1TB', '', '["1TB"]'::jsonb, 90, true, 'seed for recommendation e2e'),
    ('PSU', '650W Gold', '650W Gold', '', '["650W"]'::jsonb, 90, true, 'seed for recommendation e2e'),
    ('CASE', 'ATX Mid Tower', 'ATX Mid Tower', '', '[]'::jsonb, 90, true, 'seed for recommendation e2e'),
    ('COOLER', '120 Tower', '120 Tower', '', '[]'::jsonb, 90, true, 'seed for recommendation e2e')
ON CONFLICT (category, keyword) DO UPDATE
SET canonical_model = EXCLUDED.canonical_model,
    brand = EXCLUDED.brand,
    aliases_json = EXCLUDED.aliases_json,
    priority = EXCLUDED.priority,
    enabled = EXCLUDED.enabled,
    notes = EXCLUDED.notes,
    updated_at = NOW();

WITH seed_products(source_platform, external_id, title, url, price, category, model_tag) AS (
    VALUES
    ('jd'::source_platform, 'seed-cpu-7500f-a', 'AMD Ryzen 5 7500F 盒装', 'https://example.com/seed-cpu-7500f-a', 899::numeric, 'CPU', '7500F'),
    ('jd'::source_platform, 'seed-cpu-7500f-b', 'AMD Ryzen 5 7500F 京东自营', 'https://example.com/seed-cpu-7500f-b', 929::numeric, 'CPU', '7500F'),
    ('jd'::source_platform, 'seed-cpu-7600-a', 'AMD Ryzen 5 7600 盒装', 'https://example.com/seed-cpu-7600-a', 1099::numeric, 'CPU', '7600'),
    ('jd'::source_platform, 'seed-cpu-7600-b', 'AMD Ryzen 5 7600 旗舰店', 'https://example.com/seed-cpu-7600-b', 1129::numeric, 'CPU', '7600'),

    ('jd'::source_platform, 'seed-gpu-4060-a', 'NVIDIA GeForce RTX 4060 8G', 'https://example.com/seed-gpu-4060-a', 2399::numeric, 'GPU', 'RTX4060'),
    ('jd'::source_platform, 'seed-gpu-4060-b', 'RTX 4060 8GB 双风扇', 'https://example.com/seed-gpu-4060-b', 2499::numeric, 'GPU', 'RTX4060'),
    ('jd'::source_platform, 'seed-gpu-4060ti-a', 'NVIDIA RTX 4060 Ti 8G', 'https://example.com/seed-gpu-4060ti-a', 2999::numeric, 'GPU', 'RTX4060TI'),
    ('jd'::source_platform, 'seed-gpu-4060ti-b', 'RTX 4060 Ti 8GB OC', 'https://example.com/seed-gpu-4060ti-b', 3199::numeric, 'GPU', 'RTX4060TI'),

    ('jd'::source_platform, 'seed-mb-b650m-a', 'B650M WiFi 主板', 'https://example.com/seed-mb-b650m-a', 699::numeric, 'MB', 'B650M'),
    ('jd'::source_platform, 'seed-mb-b650m-b', 'B650M 迫击炮', 'https://example.com/seed-mb-b650m-b', 799::numeric, 'MB', 'B650M'),
    ('jd'::source_platform, 'seed-mb-b760m-a', 'B760M DDR5 主板', 'https://example.com/seed-mb-b760m-a', 729::numeric, 'MB', 'B760M'),
    ('jd'::source_platform, 'seed-mb-b760m-b', 'B760M WiFi 主板', 'https://example.com/seed-mb-b760m-b', 859::numeric, 'MB', 'B760M'),

    ('jd'::source_platform, 'seed-ram-32g-a', 'DDR5 6000 32GB 套条', 'https://example.com/seed-ram-32g-a', 499::numeric, 'RAM', '32G6000'),
    ('jd'::source_platform, 'seed-ram-32g-b', 'DDR5 6000 32G C30', 'https://example.com/seed-ram-32g-b', 539::numeric, 'RAM', '32G6000'),
    ('jd'::source_platform, 'seed-ram-16g-a', 'DDR5 6000 16GB 单条', 'https://example.com/seed-ram-16g-a', 269::numeric, 'RAM', '16G6000'),
    ('jd'::source_platform, 'seed-ram-16g-b', 'DDR5 5600 16GB', 'https://example.com/seed-ram-16g-b', 239::numeric, 'RAM', '16G5600'),

    ('jd'::source_platform, 'seed-ssd-1tb-a', 'PCIe4 NVMe 1TB SSD', 'https://example.com/seed-ssd-1tb-a', 399::numeric, 'SSD', '1TBPCIE4'),
    ('jd'::source_platform, 'seed-ssd-1tb-b', 'NVMe Gen4 1TB 固态', 'https://example.com/seed-ssd-1tb-b', 429::numeric, 'SSD', '1TBPCIE4'),
    ('jd'::source_platform, 'seed-ssd-2tb-a', 'PCIe4 NVMe 2TB SSD', 'https://example.com/seed-ssd-2tb-a', 699::numeric, 'SSD', '2TBPCIE4'),
    ('jd'::source_platform, 'seed-ssd-2tb-b', 'NVMe Gen4 2TB 固态', 'https://example.com/seed-ssd-2tb-b', 749::numeric, 'SSD', '2TBPCIE4'),

    ('jd'::source_platform, 'seed-psu-650-a', '650W 金牌全模组电源', 'https://example.com/seed-psu-650-a', 399::numeric, 'PSU', '650WGOLD'),
    ('jd'::source_platform, 'seed-psu-650-b', '650W Gold 电源', 'https://example.com/seed-psu-650-b', 429::numeric, 'PSU', '650WGOLD'),
    ('jd'::source_platform, 'seed-psu-750-a', '750W 金牌全模组电源', 'https://example.com/seed-psu-750-a', 499::numeric, 'PSU', '750WGOLD'),
    ('jd'::source_platform, 'seed-psu-750-b', '750W Gold 电源', 'https://example.com/seed-psu-750-b', 539::numeric, 'PSU', '750WGOLD'),

    ('jd'::source_platform, 'seed-case-atx-a', 'ATX 中塔机箱 侧透', 'https://example.com/seed-case-atx-a', 249::numeric, 'CASE', 'ATXMID'),
    ('jd'::source_platform, 'seed-case-atx-b', 'ATX Mid Tower 机箱', 'https://example.com/seed-case-atx-b', 279::numeric, 'CASE', 'ATXMID'),
    ('jd'::source_platform, 'seed-case-matx-a', 'mATX 小型机箱', 'https://example.com/seed-case-matx-a', 199::numeric, 'CASE', 'MATX'),
    ('jd'::source_platform, 'seed-case-matx-b', 'mATX Airflow 机箱', 'https://example.com/seed-case-matx-b', 229::numeric, 'CASE', 'MATX'),

    ('jd'::source_platform, 'seed-cooler-120-a', '120 塔式风冷', 'https://example.com/seed-cooler-120-a', 119::numeric, 'COOLER', '120TOWER'),
    ('jd'::source_platform, 'seed-cooler-120-b', '120 风冷散热器', 'https://example.com/seed-cooler-120-b', 139::numeric, 'COOLER', '120TOWER'),
    ('jd'::source_platform, 'seed-cooler-240-a', '240 一体式水冷', 'https://example.com/seed-cooler-240-a', 339::numeric, 'COOLER', '240AIO'),
    ('jd'::source_platform, 'seed-cooler-240-b', '240 水冷散热器', 'https://example.com/seed-cooler-240-b', 369::numeric, 'COOLER', '240AIO')
),
upsert_products AS (
    INSERT INTO rigel_products (
        source_platform, external_id, sku_id, title, subtitle, url, image_url, shop_name, shop_type, seller_name, region,
        price, currency, availability, attributes, raw_payload
    )
    SELECT
        source_platform,
        external_id,
        external_id,
        title,
        '',
        url,
        '',
        'Rigel Seed Shop',
        'self_operated'::shop_type,
        'Rigel Seed Seller',
        'CN',
        price,
        'CNY',
        'in_stock',
        jsonb_build_object('category', category, 'model_tag', model_tag),
        jsonb_build_object('mock', false, 'seed', true)
    FROM seed_products
    ON CONFLICT (source_platform, external_id)
    DO UPDATE SET
        title = EXCLUDED.title,
        url = EXCLUDED.url,
        price = EXCLUDED.price,
        attributes = EXCLUDED.attributes,
        raw_payload = EXCLUDED.raw_payload,
        availability = EXCLUDED.availability,
        updated_at = NOW(),
        last_seen_at = NOW()
    RETURNING id, source_platform, external_id, price
)
INSERT INTO rigel_price_snapshots (product_id, source_platform, price, in_stock, captured_at, metadata)
SELECT id, source_platform, price, true, NOW(), jsonb_build_object('seed', true, 'source', '002_seed_recommendation_test_data')
FROM upsert_products;
