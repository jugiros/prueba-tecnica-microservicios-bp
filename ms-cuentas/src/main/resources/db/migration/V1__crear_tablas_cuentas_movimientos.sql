CREATE TABLE IF NOT EXISTS cuentas (
                                       id                BIGSERIAL       PRIMARY KEY,
                                       numero_cuenta     VARCHAR(20)     NOT NULL UNIQUE,
    tipo_cuenta       VARCHAR(20)     NOT NULL,
    saldo_inicial     DECIMAL(15,2)   NOT NULL DEFAULT 0.00,
    saldo_disponible  DECIMAL(15,2)   NOT NULL DEFAULT 0.00,
    estado            BOOLEAN         NOT NULL DEFAULT TRUE,
    cliente_id        BIGINT          NOT NULL
    );

CREATE TABLE IF NOT EXISTS movimientos (
                                           id                BIGSERIAL       PRIMARY KEY,
                                           fecha             TIMESTAMP       NOT NULL,
                                           tipo_movimiento   VARCHAR(20)     NOT NULL,
    valor             DECIMAL(15,2)   NOT NULL,
    saldo             DECIMAL(15,2)   NOT NULL,
    cuenta_id         BIGINT          NOT NULL,
    CONSTRAINT fk_movimiento_cuenta
    FOREIGN KEY (cuenta_id) REFERENCES cuentas(id)
    );

CREATE INDEX IF NOT EXISTS idx_cuentas_numero ON cuentas(numero_cuenta);
CREATE INDEX IF NOT EXISTS idx_cuentas_cliente ON cuentas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_cuenta ON movimientos(cuenta_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_fecha ON movimientos(fecha);