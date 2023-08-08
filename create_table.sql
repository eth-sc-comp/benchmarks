CREATE TABLE IF NOT EXISTS results (
  solver STRING NOT NULL,
  solc_version STRING NOT NULL,
  name STRING NOT NULL,
  fun STRING NOT NULL,
  sig STRING NOT NULL,
  result STRING NOT NULL,

  correct INT,
  t FLOAT,
  tout FLOAT,
  memMB FLOAT,
  exit_status INT,
  output STRING
);
