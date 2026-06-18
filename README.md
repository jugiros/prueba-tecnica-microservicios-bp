# 🏦 Prueba Técnica Microservicios BP — DEVSU

Sistema bancario de microservicios desarrollado con Java 21, Spring Boot 4.1.0 y arquitectura hexagonal.

---

## 📋 Tabla de Contenidos

- [Tecnologías](#tecnologías)
- [Arquitectura](#arquitectura)
- [Requisitos previos](#requisitos-previos)
- [Levantamiento del sistema](#levantamiento-del-sistema)
- [Verificación del sistema](#verificación-del-sistema)
- [Pruebas con Postman](#pruebas-con-postman)
- [Orden de ejecución de APIs](#orden-de-ejecución-de-apis)
- [Solución de problemas](#solución-de-problemas)

---

## 🛠 Tecnologías

| Tecnología | Versión |
|---|---|
| Java | 21 |
| Spring Boot | 4.1.0 |
| PostgreSQL | 16-alpine |
| RabbitMQ | 3.13-management-alpine |
| MapStruct | 1.6.3 |
| Flyway | 12.4.0 |
| SpringDoc OpenAPI | 2.8.6 |
| Docker | Desktop |

---

## 🏗 Arquitectura

```
prueba-tecnica-microservicios-bp/
├── ms-clientes/          → Puerto 8081 — CRUD de clientes
├── ms-cuentas/           → Puerto 8082 — Cuentas, movimientos y reportes
├── docker-compose.yml    → Orquestación de servicios
└── banco-api.postman_collection.json
```

### Patrón: Arquitectura Hexagonal + DDD

```
infrastructure/adapter/in/rest     → Controllers (HTTP)
domain/service                     → Lógica de negocio
domain/port                        → Puertos (interfaces)
infrastructure/adapter/out/        → Persistencia y mensajería
```

---

## ✅ Requisitos Previos

- **Docker Desktop** instalado y en ejecución
- **Postman** instalado
- Puertos libres: `5432`, `5672`, `8081`, `8082`, `15672`

> ⚠️ No se requiere Java, Maven ni PostgreSQL instalados localmente.

---

## 🚀 Levantamiento del Sistema

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/jugiros/prueba-tecnica-microservicios-bp
cd prueba-tecnica-microservicios-bp
```

### Paso 2 — Construir y levantar los servicios

```bash
docker-compose up -d
```

> ⏱️ El primer levantamiento tarda entre **3 y 8 minutos** porque descarga las imágenes base y compila el código Java dentro del contenedor.

### Paso 3 — Esperar que todos los servicios estén healthy

Esperar **90 segundos** y verificar:

```bash
docker-compose ps
```

Resultado esperado:

```
NAME             STATUS
bp-postgres      Up (healthy)
bp-rabbitmq      Up (healthy)
bp-ms-clientes   Up (healthy)
bp-ms-cuentas    Up (healthy)
```

> ⚠️ Si algún contenedor aparece como `starting` esperar 30 segundos más y repetir el comando.

---

## 🔍 Verificación del Sistema

### Verificar que los servicios responden

```bash
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
```

Respuesta esperada:
```json
{"status":"UP"}
```

### Verificar que las tablas existen en PostgreSQL

```bash
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "\dt"
```

Resultado esperado:

```
 Schema |    Name     | Type  | Owner
--------+-------------+-------+--------
 public | clientes    | table | bpuser
 public | cuentas     | table | bpuser
 public | movimientos | table | bpuser
```

### Verificar Swagger UI

- ms-clientes: http://localhost:8081/swagger-ui.html
- ms-cuentas: http://localhost:8082/swagger-ui.html

---

## ⚠️ Solución de Problemas

### Problema 1 — Docker Desktop se congela al levantar

Si la interfaz gráfica de Docker Desktop se congela, usar la terminal:

```bash
# Verificar estado de contenedores
docker ps -a

# Ver logs de un contenedor específico
docker logs bp-ms-clientes --tail=30
docker logs bp-ms-cuentas --tail=30
docker logs bp-postgres --tail=20
docker logs bp-rabbitmq --tail=20
```

### Problema 2 — RabbitMQ falla al arrancar (error erlang.cookie)

```bash
docker-compose down -v
docker container prune -f
docker volume prune -f
docker-compose up -d
```

### Problema 3 — ms-clientes o ms-cuentas no arrancan

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Problema 4 — Las tablas no se crearon automáticamente

Si `\dt` retorna `Did not find any relations`, crear las tablas manualmente:

```bash
docker exec -it bp-postgres psql -U bpuser -d bpdb
```

Dentro de psql ejecutar:

```sql
CREATE TABLE IF NOT EXISTS clientes (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    genero VARCHAR(50),
    edad INTEGER,
    identificacion VARCHAR(50) UNIQUE NOT NULL,
    direccion VARCHAR(255),
    telefono VARCHAR(50),
    cliente_id VARCHAR(50) UNIQUE NOT NULL,
    contrasena VARCHAR(255) NOT NULL,
    estado BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cuentas (
    id BIGSERIAL PRIMARY KEY,
    numero_cuenta VARCHAR(50) UNIQUE NOT NULL,
    tipo_cuenta VARCHAR(50) NOT NULL,
    saldo_inicial DECIMAL(19,2) NOT NULL,
    saldo_actual DECIMAL(19,2) NOT NULL,
    estado BOOLEAN DEFAULT TRUE,
    cliente_id BIGINT NOT NULL
);

CREATE TABLE IF NOT EXISTS movimientos (
    id BIGSERIAL PRIMARY KEY,
    fecha TIMESTAMP NOT NULL,
    tipo_movimiento VARCHAR(50) NOT NULL,
    valor DECIMAL(19,2) NOT NULL,
    saldo DECIMAL(19,2) NOT NULL,
    cuenta_id BIGINT NOT NULL,
    CONSTRAINT fk_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuentas(id)
);
```

Salir de psql:

```sql
\q
```

Verificar:

```bash
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "\dt"
```

### Problema 5 — Primera petición muy lenta (30-60 segundos)

**Es normal.** La primera petición inicializa:
- Conexión a RabbitMQ
- Pool de conexiones Hikari
- Documentación Swagger

A partir de la segunda petición la respuesta es inmediata.

### Problema 6 — Error 500 en la primera petición

Reintentar la misma petición. El error ocurre porque RabbitMQ aún no terminó de inicializarse. La segunda petición funciona correctamente.

---

## 📮 Pruebas con Postman

### Importar la colección

1. Abrir Postman
2. Clic en **Import**
3. Seleccionar `banco-api.postman_collection.json`
4. Clic en **Import**

> ✅ Las URLs ya están configuradas con `http://localhost:8081` y `http://localhost:8082` — no requiere configurar variables de entorno.

---

## 📋 Orden de Ejecución de APIs

Ejecutar **estrictamente en este orden** para que los IDs sean consistentes.

---

### 1️⃣ MS-Clientes — Crear clientes

#### POST Crear Cliente — Jose Lema
```
POST http://localhost:8081/api/clientes
```
```json
{
  "nombre": "Jose Lema",
  "genero": "Masculino",
  "edad": 30,
  "identificacion": "1234567890",
  "direccion": "Otavalo sn y principal",
  "telefono": "098254785",
  "clienteId": "CLI001",
  "contrasena": "1234",
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — anotar `"id": 1`

---

#### POST Crear Cliente — Marianela Montalvo
```
POST http://localhost:8081/api/clientes
```
```json
{
  "nombre": "Marianela Montalvo",
  "genero": "Femenino",
  "edad": 28,
  "identificacion": "0987654321",
  "direccion": "Amazonas y NNUU",
  "telefono": "097548965",
  "clienteId": "CLI002",
  "contrasena": "5678",
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — anotar `"id": 2`

---

#### POST Crear Cliente — Juan Osorio
```
POST http://localhost:8081/api/clientes
```
```json
{
  "nombre": "Juan Osorio",
  "genero": "Masculino",
  "edad": 35,
  "identificacion": "1122334455",
  "direccion": "13 de junio y Equinoccial",
  "telefono": "098874587",
  "clienteId": "CLI003",
  "contrasena": "1245",
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — anotar `"id": 3`

---

### 2️⃣ MS-Cuentas — Crear cuentas

#### POST Crear Cuenta — Jose Lema Ahorros
```
POST http://localhost:8082/api/cuentas
```
```json
{
  "numeroCuenta": "478758",
  "tipoCuenta": "Ahorros",
  "saldoInicial": 2000.00,
  "clienteId": 1,
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — cuentaId: 1

---

#### POST Crear Cuenta — Marianela Corriente
```
POST http://localhost:8082/api/cuentas
```
```json
{
  "numeroCuenta": "225487",
  "tipoCuenta": "Corriente",
  "saldoInicial": 100.00,
  "clienteId": 2,
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — cuentaId: 2

---

#### POST Crear Cuenta — Marianela Ahorros
```
POST http://localhost:8082/api/cuentas
```
```json
{
  "numeroCuenta": "496825",
  "tipoCuenta": "Ahorros",
  "saldoInicial": 540.00,
  "clienteId": 2,
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — cuentaId: 3

---

#### POST Crear Cuenta — Juan Osorio Ahorros
```
POST http://localhost:8082/api/cuentas
```
```json
{
  "numeroCuenta": "495878",
  "tipoCuenta": "Ahorros",
  "saldoInicial": 0.00,
  "clienteId": 3,
  "estado": true
}
```
**Respuesta esperada:** `201 Created` — cuentaId: 4

---

### 3️⃣ MS-Movimientos — Registrar transacciones

#### POST Deposito 600 — Cuenta Jose Lema
```
POST http://localhost:8082/api/movimientos
```
```json
{
  "valor": 600.00,
  "cuentaId": 1
}
```
**Respuesta esperada:** `201` — saldo resultante: `2600.00`

---

#### POST Retiro 575 — Cuenta Jose Lema
```
POST http://localhost:8082/api/movimientos
```
```json
{
  "valor": -575.00,
  "cuentaId": 1
}
```
**Respuesta esperada:** `201` — saldo resultante: `2025.00`

---

#### POST Deposito 150 — Cuenta Marianela Corriente
```
POST http://localhost:8082/api/movimientos
```
```json
{
  "valor": 150.00,
  "cuentaId": 2
}
```
**Respuesta esperada:** `201` — saldo resultante: `250.00`

---

#### POST Retiro 540 — Cuenta Marianela Ahorros
```
POST http://localhost:8082/api/movimientos
```
```json
{
  "valor": -540.00,
  "cuentaId": 3
}
```
**Respuesta esperada:** `201` — saldo resultante: `0.00`

---

#### POST Retiro 1000 — Saldo Insuficiente (F3)
```
POST http://localhost:8082/api/movimientos
```
```json
{
  "valor": -1000.00,
  "cuentaId": 4
}
```
**Respuesta esperada:** `400 Bad Request`
```json
{
  "codigo": "SALDO_INSUFICIENTE",
  "mensaje": "Saldo no disponible",
  "status": 400
}
```

---

### 4️⃣ MS-Reportes — Reporte de estado de cuenta (F4)

> ⚠️ **IMPORTANTE — Fechas:** Los movimientos se crean con la fecha actual del servidor (año 2026). Usar el año actual en los parámetros.

#### GET Reporte — Jose Lema
```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=1
```
**Respuesta esperada:** `200 OK` con lista de movimientos de Jose Lema

---

#### GET Reporte — Marianela Montalvo
```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=2
```
**Respuesta esperada:** `200 OK` con movimientos de ambas cuentas de Marianela

---

#### GET Reporte — Juan Osorio
```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=3
```
**Respuesta esperada:** `200 OK` con `[]` — Juan Osorio no tiene movimientos registrados, lista vacía es el comportamiento correcto.

---

## 📊 Resumen de Resultados Esperados

| # | Endpoint | Método | Status Esperado | Observación |
|---|---|---|---|---|
| 1 | /api/clientes | POST | 201 | Jose Lema — id:1 |
| 2 | /api/clientes | POST | 201 | Marianela — id:2 |
| 3 | /api/clientes | POST | 201 | Juan Osorio — id:3 |
| 4 | /api/cuentas | POST | 201 | Cuenta 478758 — id:1 |
| 5 | /api/cuentas | POST | 201 | Cuenta 225487 — id:2 |
| 6 | /api/cuentas | POST | 201 | Cuenta 496825 — id:3 |
| 7 | /api/cuentas | POST | 201 | Cuenta 495878 — id:4 |
| 8 | /api/movimientos | POST | 201 | Depósito 600 |
| 9 | /api/movimientos | POST | 201 | Retiro 575 |
| 10 | /api/movimientos | POST | 201 | Depósito 150 |
| 11 | /api/movimientos | POST | 201 | Retiro 540 |
| 12 | /api/movimientos | POST | **400** | ⚠️ Saldo insuficiente |
| 13 | /api/reportes | GET | 200 | Jose Lema con movimientos |
| 14 | /api/reportes | GET | 200 | Marianela con movimientos |
| 15 | /api/reportes | GET | 200 | Juan Osorio lista vacía `[]` |

---

## 🛑 Detener el Sistema

```bash
docker-compose down
```

Para eliminar también los volúmenes (resetear la base de datos):

```bash
docker-compose down -v
```

---

## 👤 Autor

**Juan Molina** — Prueba técnica DEVSU / BP  
Repositorio: https://github.com/jugiros/prueba-tecnica-microservicios-bp
