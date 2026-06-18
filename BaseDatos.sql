--
-- BaseDatos.sql
-- Prueba Técnica Microservicios BP / DEVSU
-- Esquema de base de datos para ms-clientes y ms-cuentas
-- Base de datos: bpdb | Usuario: bpuser
-- Generado: 2026-06-18
--

-- ─────────────────────────────────────────────────
-- EXTENSIONES
-- ─────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────
-- TABLA: clientes
-- Microservicio: ms-clientes (puerto 8081)
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clientes (
    id              BIGSERIAL       PRIMARY KEY,
    nombre          VARCHAR(255)    NOT NULL,
    genero          VARCHAR(50),
    edad            INTEGER,
    identificacion  VARCHAR(50)     NOT NULL UNIQUE,
    direccion       VARCHAR(255),
    telefono        VARCHAR(50),
    cliente_id      VARCHAR(50)     NOT NULL UNIQUE,
    contrasena      VARCHAR(255)    NOT NULL,
    estado          BOOLEAN         NOT NULL DEFAULT TRUE
);

COMMENT ON TABLE  clientes                IS 'Entidad Cliente que hereda atributos de Persona. Gestionada por ms-clientes.';
COMMENT ON COLUMN clientes.id             IS 'Clave primaria autoincremental';
COMMENT ON COLUMN clientes.nombre         IS 'Nombre completo del cliente';
COMMENT ON COLUMN clientes.genero         IS 'Genero del cliente';
COMMENT ON COLUMN clientes.edad           IS 'Edad del cliente';
COMMENT ON COLUMN clientes.identificacion IS 'Numero de identificacion unico (cedula/pasaporte)';
COMMENT ON COLUMN clientes.direccion      IS 'Direccion domiciliaria';
COMMENT ON COLUMN clientes.telefono       IS 'Numero de telefono de contacto';
COMMENT ON COLUMN clientes.cliente_id     IS 'Identificador de negocio unico del cliente (CLI001, CLI002...)';
COMMENT ON COLUMN clientes.contrasena     IS 'Contrasena de acceso del cliente';
COMMENT ON COLUMN clientes.estado         IS 'Estado activo/inactivo del cliente. TRUE = activo';

-- ─────────────────────────────────────────────────
-- TABLA: cuentas
-- Microservicio: ms-cuentas (puerto 8082)
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cuentas (
    id              BIGSERIAL       PRIMARY KEY,
    numero_cuenta   VARCHAR(50)     NOT NULL UNIQUE,
    tipo_cuenta     VARCHAR(50)     NOT NULL,
    saldo_inicial   DECIMAL(19,2)   NOT NULL,
    saldo_actual    DECIMAL(19,2)   NOT NULL,
    estado          BOOLEAN         NOT NULL DEFAULT TRUE,
    cliente_id      BIGINT          NOT NULL
);

COMMENT ON TABLE  cuentas               IS 'Entidad Cuenta bancaria. Gestionada por ms-cuentas.';
COMMENT ON COLUMN cuentas.id            IS 'Clave primaria autoincremental';
COMMENT ON COLUMN cuentas.numero_cuenta IS 'Numero de cuenta bancaria unico';
COMMENT ON COLUMN cuentas.tipo_cuenta   IS 'Tipo de cuenta: Ahorros o Corriente';
COMMENT ON COLUMN cuentas.saldo_inicial IS 'Saldo con el que se apertura la cuenta';
COMMENT ON COLUMN cuentas.saldo_actual  IS 'Saldo disponible actualizado con cada movimiento';
COMMENT ON COLUMN cuentas.estado        IS 'Estado activo/inactivo de la cuenta. TRUE = activa';
COMMENT ON COLUMN cuentas.cliente_id    IS 'ID del cliente propietario de la cuenta (referencia logica a clientes.id)';

-- ─────────────────────────────────────────────────
-- TABLA: movimientos
-- Microservicio: ms-cuentas (puerto 8082)
-- ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS movimientos (
    id               BIGSERIAL       PRIMARY KEY,
    fecha            TIMESTAMP       NOT NULL DEFAULT NOW(),
    tipo_movimiento  VARCHAR(50)     NOT NULL,
    valor            DECIMAL(19,2)   NOT NULL,
    saldo            DECIMAL(19,2)   NOT NULL,
    cuenta_id        BIGINT          NOT NULL,
    CONSTRAINT fk_movimiento_cuenta
        FOREIGN KEY (cuenta_id)
        REFERENCES cuentas(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

COMMENT ON TABLE  movimientos                IS 'Registro de todas las transacciones bancarias. Gestionada por ms-cuentas.';
COMMENT ON COLUMN movimientos.id             IS 'Clave primaria autoincremental';
COMMENT ON COLUMN movimientos.fecha          IS 'Fecha y hora exacta del movimiento';
COMMENT ON COLUMN movimientos.tipo_movimiento IS 'Tipo: Deposito (valor positivo) o Retiro (valor negativo)';
COMMENT ON COLUMN movimientos.valor          IS 'Monto del movimiento. Positivo = deposito, Negativo = retiro';
COMMENT ON COLUMN movimientos.saldo          IS 'Saldo disponible de la cuenta despues de aplicar el movimiento';
COMMENT ON COLUMN movimientos.cuenta_id      IS 'FK hacia la cuenta que origina el movimiento';

-- ─────────────────────────────────────────────────
-- INDICES para optimizar consultas frecuentes
-- ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_clientes_identificacion ON clientes(identificacion);
CREATE INDEX IF NOT EXISTS idx_clientes_cliente_id     ON clientes(cliente_id);
CREATE INDEX IF NOT EXISTS idx_cuentas_numero_cuenta   ON cuentas(numero_cuenta);
CREATE INDEX IF NOT EXISTS idx_cuentas_cliente_id      ON cuentas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_cuenta_id   ON movimientos(cuenta_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_fecha       ON movimientos(fecha);

-- ─────────────────────────────────────────────────
-- DATOS DE PRUEBA — Casos de uso del enunciado
-- ─────────────────────────────────────────────────

-- Clientes
INSERT INTO clientes (nombre, genero, edad, identificacion, direccion, telefono, cliente_id, contrasena, estado) VALUES
    ('Jose Lema',         'Masculino', 30, '1234567890', 'Otavalo sn y principal',    '098254785', 'CLI001', '1234', TRUE),
    ('Marianela Montalvo','Femenino',  28, '0987654321', 'Amazonas y NNUU',           '097548965', 'CLI002', '5678', TRUE),
    ('Juan Osorio',       'Masculino', 35, '1122334455', '13 de junio y Equinoccial', '098874587', 'CLI003', '1245', TRUE)
ON CONFLICT (identificacion) DO NOTHING;

-- Cuentas
INSERT INTO cuentas (numero_cuenta, tipo_cuenta, saldo_inicial, saldo_actual, estado, cliente_id) VALUES
    ('478758', 'Ahorros',   2000.00, 2000.00, TRUE, 1),
    ('225487', 'Corriente',  100.00,  100.00, TRUE, 2),
    ('495878', 'Ahorros',      0.00,    0.00, TRUE, 3),
    ('496825', 'Ahorros',    540.00,  540.00, TRUE, 2),
    ('585545', 'Corriente', 1000.00, 1000.00, TRUE, 1)
ON CONFLICT (numero_cuenta) DO NOTHING;

