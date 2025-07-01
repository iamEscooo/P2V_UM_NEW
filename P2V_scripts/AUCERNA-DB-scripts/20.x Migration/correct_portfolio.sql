-- correct Portfolio datasources
-- as datasource cannot be changed via GUI - replace it in the Portfolio DB

UPDATE dbo.DataSources SET Config = REPLACE(Config, 'https://ips20-test.ww.omv.com/TRAINING', 'https://ips20-prod.ww.omv.com/PROD');