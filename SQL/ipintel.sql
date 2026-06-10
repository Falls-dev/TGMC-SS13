-- IPINTEL cache table (optional; API still works without DB, but without persistence).
-- Apply to your feedback database if IPINTEL_EMAIL is set in config.

CREATE TABLE IF NOT EXISTS `ipintel` (
  `ip` int(10) unsigned NOT NULL,
  `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `intel` double NOT NULL DEFAULT '0',
  PRIMARY KEY (`ip`),
  KEY `idx_ipintel` (`ip`,`intel`,`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
