CREATE TABLE IF NOT EXISTS tb_address (
    id       SERIAL PRIMARY KEY,
    street   VARCHAR(50) NULL,
    city     VARCHAR(50) NULL,
    state    VARCHAR(50) NULL,
    postal_code VARCHAR(50) NULL,
    dh_insert TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tb_client (
    id         SERIAL PRIMARY KEY,
    password   VARCHAR(500) NOT NULL,
    email      VARCHAR(50) NULL,
    cpf        VARCHAR(50) NULL UNIQUE,
    name       VARCHAR(50) NOT NULL,
    id_address INTEGER REFERENCES tb_address(id),
    dh_insert TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tb_category (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(250) NOT NULL UNIQUE,
    description VARCHAR(250) NULL,
    dh_insert TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tb_product (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR NOT NULL,
    price       NUMERIC NOT NULL,
    quantity    INTEGER NULL,
    id_category INTEGER REFERENCES tb_category(id),
    dh_insert TIMESTAMP DEFAULT NOW()
);

CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";

CREATE TABLE IF NOT EXISTS tb_order (
  id                  SERIAL  PRIMARY KEY,
  external_id         uuid    DEFAULT uuid_generate_v4() NOT NULL,
  id_client           INTEGER REFERENCES tb_client(id) NOT NULL,
  total_price         NUMERIC NOT NULL,
  status              VARCHAR(50) NULL,
  waiting_time        TIMESTAMP NULL,
  is_finished         BOOLEAN DEFAULT FALSE,
  dh_insert TIMESTAMP DEFAULT NOW()
);
  
CREATE TABLE IF NOT EXISTS tb_order_product (
  id                  SERIAL  PRIMARY KEY,
  id_product          INTEGER REFERENCES tb_product(id),
  id_order            INTEGER REFERENCES tb_order(id)
);
