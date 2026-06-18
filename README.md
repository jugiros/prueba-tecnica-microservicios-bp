# 🏦 Prueba Técnica Microservicios BP — DEVSU

Sistema bancario de microservicios desarrollado con Java 21, Spring Boot 4.1.0 y arquitectura hexagonal.

---

## 📋 Tabla de Contenidos

- [Tecnologías](#tecnologías)
- [Arquitectura](#arquitectura)
- [Requisitos previos](#requisitos-previos)
- [Verificar puertos libres](#verificar-puertos-libres)
- [Levantamiento del sistema](#levantamiento-del-sistema)
- [Verificación del sistema](#verificación-del-sistema)
- [Pruebas con Postman](#pruebas-con-postman)
- [Orden de ejecución de APIs](#orden-de-ejecución-de-apis)
- [Solución de problemas](#solución-de-problemas)
- [Detener el sistema](#detener-el-sistema)

---

## 🛠 Tecnologías

| Tecnología | Versión |
|---|---|
| Java | 21 |
| Spring Boot | 4.1.0 |
| PostgreSQL | 16-alpine |
| RabbitMQ | 3.13-management-alpine |
| MapStruct | 1.6.3 |
| SpringDoc OpenAPI | 2.8.6 |
| Docker Desktop | Latest |

---

## 🏗 Arquitectura

```
prueba-tecnica-microservicios-bp/
├── ms-clientes/          → Puerto 8081 — CRUD de clientes
├── ms-cuentas/           → Puerto 8082 — Cuentas, movimientos y reportes
├── docker-compose.yml    → Orquestación de servicios
└── banco-api.postman_collection.json
```

Patrón: **Arquitectura Hexagonal + DDD**

---

## ✅ Requisitos Previos

- **Docker Desktop** instalado
- **Postman** instalado
- Puertos libres: `5432`, `5672`, `8081`, `8082`, `15672`

> ⚠️ No se requiere Java, Maven ni PostgreSQL instalados localmente.

---

## 🔌 Verificar Puertos Libres

Antes de levantar el sistema verificar que los puertos estén disponibles.
Si algún comando retorna resultados el puerto está ocupado y Docker fallará.

```powershell
netstat -an | findstr :5432
netstat -an | findstr :5672
netstat -an | findstr :8081
netstat -an | findstr :8082
netstat -an | findstr :15672
```

| Puerto | Servicio | Si está ocupado |
|---|---|---|
| 5432 | PostgreSQL | Detener PostgreSQL local |
| 5672 | RabbitMQ AMQP | Detener otro broker AMQP |
| 8081 | ms-clientes HTTP | Detener proceso en ese puerto |
| 8082 | ms-cuentas HTTP | Detener proceso en ese puerto |
| 15672 | RabbitMQ Management UI | No crítico — solo afecta el panel web |

---

## 🚀 Levantamiento del Sistema

> ⚠️ **IMPORTANTE**: Todos los comandos deben ejecutarse desde la carpeta raíz del proyecto.
> Si Docker Desktop tiene problemas con la interfaz gráfica, usar únicamente PowerShell.

### Paso 1 — Clonar el repositorio

```powershell
git clone https://github.com/jugiros/prueba-tecnica-microservicios-bp
cd prueba-tecnica-microservicios-bp
```

### Paso 2 — Iniciar Docker Desktop desde PowerShell

Si Docker Desktop no está abierto, iniciarlo desde consola:

```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

Esperar 60 segundos y verificar que Docker esté listo:

```powershell
docker ps
```

Resultado esperado (sin errores):
```
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

> Si aparece un error esperar 30 segundos más y repetir `docker ps`.

### Paso 3 — Limpiar estado previo (si aplica)

Si el sistema ya fue levantado anteriormente, limpiar completamente:

```powershell
docker-compose down -v
docker container prune -f
docker volume prune -f
```

Verificar que quedó limpio:

```powershell
docker ps -a
docker volume ls
```

Ambos deben retornar vacío.

### Paso 4 — Levantar el sistema

```powershell
docker-compose up -d
```

> ⏱️ **Primera vez**: 5-8 minutos (descarga imágenes y compila el código Java).
> ⏱️ **Siguientes veces**: 15-30 segundos (imágenes ya están en caché).

Resultado esperado:

```
✔ Network  bp-network    Created
✔ Volume   postgres_data Created
✔ Container bp-postgres  Healthy
✔ Container bp-rabbitmq  Healthy
✔ Container bp-ms-clientes Healthy
✔ Container bp-ms-cuentas  Started
```

### Paso 5 — Verificar estado de los contenedores

Esperar 90 segundos y ejecutar:

```powershell
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

> Si algún contenedor aparece como `starting` esperar 30 segundos más y repetir.

---

## 🔍 Verificación del Sistema

### Verificar tablas en PostgreSQL

```powershell
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "\dt"
```

Resultado esperado:

```
 Schema |    Name     | Type  | Owner
--------+-------------+-------+--------
 public | clientes    | table | bpuser
 public | cuentas     | table | bpuser
 public | movimientos | table | bpuser
(3 rows)
```

### Verificar health de los microservicios

```powershell
docker logs bp-ms-clientes --tail=5
docker logs bp-ms-cuentas --tail=5
```

### Verificar Swagger UI (navegador)

- ms-clientes: http://localhost:8081/swagger-ui.html
- ms-cuentas: http://localhost:8082/swagger-ui.html

---

## ⚠️ Solución de Problemas

### Problema 1 — Docker Desktop no inicia o interfaz gráfica congelada

Usar exclusivamente PowerShell:

```powershell
# Iniciar Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Esperar 60 segundos
Start-Sleep -Seconds 60

# Verificar
docker ps
```

### Problema 2 — RabbitMQ falla con error erlang.cookie

```powershell
docker-compose down -v
docker container prune -f
docker volume prune -f
docker-compose up -d
```

### Problema 3 — Contenedor ms-clientes o ms-cuentas no arranca

Ver logs del error:

```powershell
docker logs bp-ms-clientes --tail=30
docker logs bp-ms-cuentas --tail=30
```

Reconstruir imágenes:

```powershell
docker-compose down
docker-compose build --no-cache ms-clientes ms-cuentas
docker-compose up -d
```

### Problema 4 — Las tablas no se crearon automáticamente

Si `\dt` retorna `Did not find any relations`, crear las tablas manualmente:

```powershell
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

```powershell
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "\dt"
```

### Problema 5 — Primera petición muy lenta (30-60 segundos)

**Es normal.** La primera petición inicializa la conexión a RabbitMQ y el pool de Hikari. A partir de la segunda petición la respuesta es inmediata.

### Problema 6 — Error 500 en la primera petición

Reintentar la misma petición. La segunda petición funciona correctamente.

### Problema 7 — Reporte retorna lista vacía []

Verificar que las fechas correspondan al año actual. Los movimientos se crean con la fecha del servidor (2026):

```
fechaInicio=2026-01-01T00:00:00
fechaFin=2026-12-31T23:59:59
```

---

## 📮 Pruebas con Postman

### Importar la colección

1. Abrir Postman
2. Clic en **Import**
3. Seleccionar `banco-api.postman_collection.json`
4. Clic en **Import**

> ✅ Las URLs ya están configuradas con `http://localhost:8081` y `http://localhost:8082`.
> No se requiere configurar variables de entorno en Postman.

---

## 📋 Orden de Ejecución de APIs

Ejecutar **estrictamente en este orden**.

---

### 1️⃣ Crear Clientes

```
POST http://localhost:8081/api/clientes
Content-Type: application/json
```

**Jose Lema:**
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
✅ Esperado: `201 Created` — id: 1

**Marianela Montalvo:**
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
✅ Esperado: `201 Created` — id: 2

**Juan Osorio:**
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
✅ Esperado: `201 Created` — id: 3

---

### 2️⃣ Crear Cuentas

```
POST http://localhost:8082/api/cuentas
Content-Type: application/json
```

**Cuenta Ahorros Jose Lema:**
```json
{ "numeroCuenta": "478758", "tipoCuenta": "Ahorros", "saldoInicial": 2000.00, "clienteId": 1, "estado": true }
```
✅ Esperado: `201` — cuentaId: 1

**Cuenta Corriente Marianela:**
```json
{ "numeroCuenta": "225487", "tipoCuenta": "Corriente", "saldoInicial": 100.00, "clienteId": 2, "estado": true }
```
✅ Esperado: `201` — cuentaId: 2

**Cuenta Ahorros Marianela:**
```json
{ "numeroCuenta": "496825", "tipoCuenta": "Ahorros", "saldoInicial": 540.00, "clienteId": 2, "estado": true }
```
✅ Esperado: `201` — cuentaId: 3

**Cuenta Ahorros Juan Osorio:**
```json
{ "numeroCuenta": "495878", "tipoCuenta": "Ahorros", "saldoInicial": 0.00, "clienteId": 3, "estado": true }
```
✅ Esperado: `201` — cuentaId: 4

---

### 3️⃣ Registrar Movimientos

```
POST http://localhost:8082/api/movimientos
Content-Type: application/json
```

| # | Body | Saldo resultante |
|---|---|---|
| 1 | `{ "valor": 600.00, "cuentaId": 1 }` | 2600.00 |
| 2 | `{ "valor": -575.00, "cuentaId": 1 }` | 2025.00 |
| 3 | `{ "valor": 150.00, "cuentaId": 2 }` | 250.00 |
| 4 | `{ "valor": -540.00, "cuentaId": 3 }` | 0.00 |

✅ Todos esperan `201 Created`

---

### 4️⃣ Prueba Saldo Insuficiente (F3)

```
POST http://localhost:8082/api/movimientos
```
```json
{ "valor": -1000.00, "cuentaId": 4 }
```

⛔ Esperado: `400 Bad Request`
```json
{ "mensaje": "Saldo no disponible" }
```

---

### 5️⃣ Reportes F4

> ⚠️ **Usar año 2026** — los movimientos se crean con la fecha del servidor.

```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=1
```
✅ Esperado: `200 OK` con movimientos de Jose Lema

```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=2
```
✅ Esperado: `200 OK` con movimientos de Marianela

```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=3
```
✅ Esperado: `200 OK` con `[]` — Juan Osorio no tiene movimientos, es correcto.

---

## 📊 Resumen de Resultados Esperados

| # | Endpoint | Método | Status |
|---|---|---|---|
| 1-3 | /api/clientes | POST | 201 |
| 4-7 | /api/cuentas | POST | 201 |
| 8-11 | /api/movimientos | POST | 201 |
| 12 | /api/movimientos (saldo insuf.) | POST | **400** |
| 13-15 | /api/reportes | GET | 200 |

---

## 🛑 Detener el Sistema

```powershell
# Detener preservando datos
docker-compose down

# Detener y eliminar todos los datos (reset completo)
docker-compose down -v
```

---

## 👤 Autor

**Juan Molina** — Prueba técnica DEVSU / BP
Repositorio: https://github.com/jugiros/prueba-tecnica-microservicios-bp

---

## 🎯 Validación de Funcionalidades F1 — F7

Resumen de cumplimiento de cada requerimiento de la prueba técnica.

---

### F1 — CRUD Cliente / CRU Cuenta y Movimiento ✅

| Entidad | Operaciones | Endpoint | Puerto |
|---|---|---|---|
| Cliente | GET, POST, PUT, PATCH, **DELETE** | `/api/clientes` | 8081 |
| Cuenta | GET, POST, PUT, PATCH | `/api/cuentas` | 8082 |
| Movimiento | GET, POST, PUT | `/api/movimientos` | 8082 |

Cómo probar:
```
POST   http://localhost:8081/api/clientes       → 201
GET    http://localhost:8081/api/clientes       → 200
GET    http://localhost:8081/api/clientes/1     → 200
PUT    http://localhost:8081/api/clientes/1     → 200
PATCH  http://localhost:8081/api/clientes/1     → 200
DELETE http://localhost:8081/api/clientes/1     → 204
```

---

### F2 — Registro de movimientos con actualización de saldo ✅

- Valor positivo → **Depósito** → suma al saldo actual
- Valor negativo → **Retiro** → resta del saldo actual
- Cada movimiento queda registrado con fecha, tipo, valor y saldo resultante

Cómo probar:
```
POST http://localhost:8082/api/movimientos
Body: { "valor": -575.00, "cuentaId": 1 }   → Retiro   → 201
Body: { "valor":  600.00, "cuentaId": 2 }   → Deposito → 201
```

---

### F3 — Saldo no disponible ✅

Cuando el valor del retiro supera el saldo disponible retorna **400**:

```
POST http://localhost:8082/api/movimientos
Body: { "valor": -1000.00, "cuentaId": 3 }
```

Respuesta:
```json
{ "mensaje": "Saldo no disponible" }
```

---

### F4 — Reporte estado de cuenta por fechas y cliente ✅

```
GET http://localhost:8082/api/reportes
  ?fechaInicio=2026-01-01T00:00:00
  &fechaFin=2026-12-31T23:59:59
  &clienteId=1
```

Retorna JSON con: fecha, cliente, numeroCuenta, tipo, saldoInicial, estado, movimiento, saldoDisponible.

> ⚠️ Usar **año 2026** — los movimientos se registran con la fecha actual del servidor.
> Juan Osorio retorna `[]` si no tiene movimientos — es el comportamiento correcto.

---

### F5 — Prueba unitaria entidad Cliente ✅

6 pruebas JUnit 5 + Mockito en ms-clientes:

```bash
cd ms-clientes
mvn test
```

Resultado esperado: `BUILD SUCCESS — Tests run: 6, Failures: 0`

---

### F6 — Prueba de integración ⚠️

Marcada como **deseable** en el enunciado — no implementada en esta entrega.

---

### F7 — Despliegue en Docker ✅

Un solo comando levanta los 4 servicios:

```powershell
docker-compose up -d
```

Servicios:

| Contenedor | Imagen | Puerto |
|---|---|---|
| bp-postgres | postgres:16-alpine | 5432 |
| bp-rabbitmq | rabbitmq:3.13-management-alpine | 5672, 15672 |
| bp-ms-clientes | Multistage build Java 21 | 8081 |
| bp-ms-cuentas | Multistage build Java 21 | 8082 |

---

## 📁 Entregables

| Archivo | Descripción |
|---|---|
| `ms-clientes/` | Microservicio CRUD clientes — arquitectura hexagonal |
| `ms-cuentas/` | Microservicio cuentas, movimientos y reportes |
| `docker-compose.yml` | Orquestación completa de 4 servicios |
| `BaseDatos.sql` | Script SQL con esquema completo y datos de prueba |
| `banco-api.postman_collection.json` | Colección Postman con los 16 endpoints |
| `README.md` | Este archivo — instrucciones completas |
| `ms-clientes/README.md` | Documentación técnica de ms-clientes |
| `ms-cuentas/README.md` | Documentación técnica de ms-cuentas |

Repositorio: https://github.com/jugiros/prueba-tecnica-microservicios-bp
