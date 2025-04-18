-- Configurar variáveis de servidor para maior durabilidade
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;
SET GLOBAL max_allowed_packet = 67108864;

-- Habilitar verificação automática de tabelas
SET GLOBAL innodb_background_scrub = 1;
SET GLOBAL innodb_stats_auto_recalc = 1;

-- Otimizar para recuperação após falhas
SET GLOBAL innodb_print_all_deadlocks = 1;
SET GLOBAL innodb_checksum_algorithm = 'crc32';