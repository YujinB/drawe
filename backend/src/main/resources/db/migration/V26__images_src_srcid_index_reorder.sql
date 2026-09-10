-- idx_img_src_srcId 는 (source, source_id) 순서였으나, findBySourceIdIn(source_id IN (...))
-- 조회가 leftmost prefix 규칙 때문에 이 인덱스를 못 타고 풀스캔되는 문제가 있었다.
-- (source_id, source) 로 순서를 바꾸면 source_id 단독 조회도 인덱스를 타고,
-- source + source_id 동등조건 조회(findFirstBySourceAndSourceId)도 순서 무관하게 여전히 인덱스를 타서
-- 인덱스 1개로 두 쿼리 패턴을 모두 커버한다.
--
-- 멱등 처리: 이미 (source_id, source) 순서면 no-op.
SET @needs_reorder := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'images'
    AND INDEX_NAME = 'idx_img_src_srcId' AND SEQ_IN_INDEX = 1 AND COLUMN_NAME = 'source_id'
);
SET @ddl := IF(@needs_reorder = 0,
  'ALTER TABLE `images` DROP INDEX `idx_img_src_srcId`, ADD INDEX `idx_img_src_srcId` (`source_id`, `source`)',
  'DO 0');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
