DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'rigel_part_market_summary'
    ) THEN
        ALTER TABLE rigel_part_market_summary
            ADD COLUMN IF NOT EXISTS snapshot_date DATE;

        UPDATE rigel_part_market_summary
        SET snapshot_date = COALESCE(DATE(last_collected_at), CURRENT_DATE)
        WHERE snapshot_date IS NULL;

        ALTER TABLE rigel_part_market_summary
            ALTER COLUMN snapshot_date SET NOT NULL;

        IF EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'rigel_part_market_summary_part_id_source_platform_window_da_key'
        ) THEN
            ALTER TABLE rigel_part_market_summary
                DROP CONSTRAINT rigel_part_market_summary_part_id_source_platform_window_da_key;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conrelid = 'rigel_part_market_summary'::regclass
              AND contype = 'u'
              AND pg_get_constraintdef(oid) LIKE 'UNIQUE (part_id, source_platform, snapshot_date)%'
        ) THEN
            ALTER TABLE rigel_part_market_summary
                ADD CONSTRAINT uq_rigel_part_market_summary_snapshot
                UNIQUE (part_id, source_platform, snapshot_date);
        END IF;

        CREATE INDEX IF NOT EXISTS idx_rigel_part_market_summary_snapshot_date
            ON rigel_part_market_summary(snapshot_date DESC);
    END IF;
END $$;
