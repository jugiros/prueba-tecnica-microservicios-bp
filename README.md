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
- [Pruebas unitarias e integración](#pruebas-unitarias-e-integración)
- [Pruebas con Postman](#pruebas-con-postman)
- [Orden de ejecución de APIs](#orden-de-ejecución-de-apis)
- [Validación F1-F7](#validación-f1---f7)
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
| Testcontainers | 1.20.4 |
| SpringDoc OpenAPI | 2.8.6 |
| Docker Desktop | Latest |

---

## 🏗 Arquitectura

```
prueba-tecnica-microservicios-bp/
├── ms-clientes/          → Puerto 8081 — CRUD de clientes
├── ms-cuentas/           → Puerto 8082 — Cuentas, movimientos y reportes
├── docker-compose.yml    → Orquestación de 4 servicios
├── BaseDatos.sql         → Script SQL con esquema y datos de prueba
└── banco-api.postman_collection.json
```

Patrón: **Arquitectura Hexagonal + DDD**

```
domain/model/                        → Entidades de dominio puras
domain/port/in/                      → Puertos de entrada (casos de uso)
domain/port/out/                     → Puertos de salida (repositorios)
domain/service/                      → Lógica de negocio
infrastructure/adapter/in/rest/      → Controladores HTTP (adaptadores de entrada)
infrastructure/adapter/out/persistence/ → JPA (adaptadores de salida)
infrastructure/adapter/out/messaging/   → RabbitMQ (adaptadores de salida)
```

---

## ✅ Requisitos Previos

- **Docker Desktop** instalado
- **Postman** instalado
- Puertos libres: `5432`, `5672`, `8081`, `8082`, `15672`

> ⚠️ No se requiere Java, Maven ni PostgreSQL instalados localmente.

---

## 🔌 Verificar Puertos Libres

```powershell
netstat -an | findstr :5432
netstat -an | findstr :5672
netstat -an | findstr :8081
netstat -an | findstr :8082
netstat -an | findstr :15672
```

Si algún comando retorna resultados el puerto está ocupado y Docker fallará.

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
> La interfaz gráfica de Docker Desktop **no es necesaria en ningún momento** — todo funciona desde PowerShell.

### ⚠️ Si Docker Desktop tiene la interfaz gráfica congelada

No cerrar ni reinstalar. Usar exclusivamente PowerShell para todo el proceso:

```powershell
# Iniciar Docker Desktop desde consola — no usar el ícono de escritorio
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Esperar que Docker arranque completamente
Start-Sleep -Seconds 60

# Verificar que Docker responde — debe mostrar tabla vacía sin error
docker ps

# Si responde sin error, continuar con los siguientes pasos normalmente
# Si sigue fallando, esperar 30 segundos más y repetir docker ps
```

> ✅ Una vez que `docker ps` responde sin error, Docker está listo aunque la interfaz gráfica esté congelada o no visible.

---

### Paso 1 — Clonar el repositorio

```powershell
git clone https://github.com/jugiros/prueba-tecnica-microservicios-bp
cd prueba-tecnica-microservicios-bp
```

### Paso 2 — Iniciar Docker Desktop desde PowerShell

```powershell
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
```

Esperar 60 segundos y verificar:

```powershell
docker ps
```

Resultado esperado (sin errores):
```
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

### Paso 3 — Limpiar estado previo (si aplica)

```powershell
docker-compose down -v
docker container prune -f
docker volume prune -f
```

### Paso 4 — Levantar el sistema

```powershell
docker-compose up -d
```

> ⏱️ **Primera vez**: 5-8 minutos. **Siguientes veces**: 15-30 segundos.

Resultado esperado:
```
✔ Container bp-postgres    Healthy
✔ Container bp-rabbitmq    Healthy
✔ Container bp-ms-clientes Healthy
✔ Container bp-ms-cuentas  Started
```

### Paso 5 — Verificar estado

```powershell
docker-compose ps
```

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
```

### Verificar Swagger UI

- ms-clientes: http://localhost:8081/swagger-ui.html
- ms-cuentas: http://localhost:8082/swagger-ui.html

---

## 🧪 Pruebas Unitarias e Integración

### F5 — Pruebas Unitarias (sin Docker requerido)

```powershell
cd ms-clientes
mvn test
cd ..
```

Resultado esperado:
```
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

Pruebas incluidas:
| Prueba | Qué verifica |
|---|---|
| `debeCrearClienteExitosamente` | Creación exitosa de cliente |
| `debeLanzarExcepcionSiClienteIdDuplicado` | Unicidad de clienteId |
| `debeObtenerClientePorId` | Consulta por ID exitosa |
| `debeLanzarExcepcionSiClienteNoExiste` | Error 404 cuando no existe |
| `debeEliminarClienteExitosamente` | Eliminación correcta |
| `MsClientesApplicationTests` | Contexto Spring Boot válido |

---

### F6 — Prueba de Integración con Testcontainers

La prueba de integración usa **Testcontainers** para levantar un PostgreSQL real en Docker y prueba el endpoint `/api/clientes` completo end-to-end.

> ⚠️ Requiere Docker Desktop activo y ejecutarse con el perfil `integration-test`.

```powershell
cd ms-clientes
mvn test -P integration-test
cd ..
```

Resultado esperado:
```
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

Pruebas de integración incluidas:
| Prueba | Qué verifica |
|---|---|
| `crearCliente_retorna201` | POST crea cliente en PostgreSQL real — retorna 201 |
| `listarClientes_retorna200` | GET lista clientes — retorna 200 |
| `crearCliente_identificacionDuplicada_retorna400` | Constraint de unicidad en BD real — retorna 400 |
| `obtenerCliente_noExiste_retorna404` | GlobalExceptionHandler retorna 404 |
| `eliminarCliente_existente_retorna204` | DELETE elimina cliente — retorna 204 |

**Por qué está separado del build normal:**
Docker Desktop en Windows usa Named Pipes (`npipe`) que Maven no puede acceder directamente sin configuración adicional del sistema. Para garantizar que `mvn test` funcione en cualquier máquina sin configuración previa, F6 se ejecuta con un perfil Maven separado (`-P integration-test`) cuando Docker está disponible.

---

## 📮 Pruebas con Postman

### Importar la colección

1. Abrir Postman
2. Clic en **Import**
3. Seleccionar `banco-api.postman_collection.json`
4. Clic en **Import**

> ✅ URLs ya configuradas — no requiere variables de entorno.

---

## 📋 Orden de Ejecución de APIs

Ejecutar **estrictamente en este orden**.

### 1️⃣ Crear Clientes — `POST http://localhost:8081/api/clientes`

**Jose Lema:**
```json
{
  "nombre": "Jose Lema", "genero": "Masculino", "edad": 30,
  "identificacion": "1234567890", "direccion": "Otavalo sn y principal",
  "telefono": "098254785", "clienteId": "CLI001", "contrasena": "1234", "estado": true
}
```
✅ `201 Created` — id: 1

**Marianela Montalvo:**
```json
{
  "nombre": "Marianela Montalvo", "genero": "Femenino", "edad": 28,
  "identificacion": "0987654321", "direccion": "Amazonas y NNUU",
  "telefono": "097548965", "clienteId": "CLI002", "contrasena": "5678", "estado": true
}
```
✅ `201 Created` — id: 2

**Juan Osorio:**
```json
{
  "nombre": "Juan Osorio", "genero": "Masculino", "edad": 35,
  "identificacion": "1122334455", "direccion": "13 de junio y Equinoccial",
  "telefono": "098874587", "clienteId": "CLI003", "contrasena": "1245", "estado": true
}
```
✅ `201 Created` — id: 3

---

### 2️⃣ Crear Cuentas — `POST http://localhost:8082/api/cuentas`

```json
{ "numeroCuenta": "478758", "tipoCuenta": "Ahorros",   "saldoInicial": 2000.00, "clienteId": 1, "estado": true }
{ "numeroCuenta": "225487", "tipoCuenta": "Corriente", "saldoInicial": 100.00,  "clienteId": 2, "estado": true }
{ "numeroCuenta": "495878", "tipoCuenta": "Ahorros",   "saldoInicial": 0.00,    "clienteId": 3, "estado": true }
{ "numeroCuenta": "496825", "tipoCuenta": "Ahorros",   "saldoInicial": 540.00,  "clienteId": 2, "estado": true }
{ "numeroCuenta": "585545", "tipoCuenta": "Corriente", "saldoInicial": 1000.00, "clienteId": 1, "estado": true }
```
✅ Todas `201 Created` — cuentaIds: 1, 2, 3, 4, 5

---

### 3️⃣ Movimientos — `POST http://localhost:8082/api/movimientos`

| # | Body | Resultado |
|---|---|---|
| 9 | `{ "valor": -575.00, "cuentaId": 1 }` | Retiro — saldo: 1425.00 — `201` |
| 10 | `{ "valor": 600.00,  "cuentaId": 2 }` | Depósito — saldo: 700.00 — `201` |
| 11 | `{ "valor": 150.00,  "cuentaId": 3 }` | Depósito — saldo: 150.00 — `201` |
| 12 | `{ "valor": -540.00, "cuentaId": 4 }` | Retiro — saldo: 0.00 — `201` |

---

### 4️⃣ Saldo Insuficiente F3 — `POST http://localhost:8082/api/movimientos`

```json
{ "valor": -1000.00, "cuentaId": 3 }
```
⛔ `400 Bad Request` → `{ "mensaje": "Saldo no disponible" }`

---

### 5️⃣ Reportes F4 — `GET http://localhost:8082/api/reportes`

> ⚠️ **Usar año 2026** — los movimientos se registran con la fecha actual del servidor.

```
?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=1  → 200 con movimientos
?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=2  → 200 con movimientos
?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=3  → 200 con [] (correcto)
```

> Juan Osorio retorna `[]` — correcto, su depósito de 150 fue revertido por el intento de retiro fallido.

---

## 🎯 Validación F1 — F7

| F | Descripción | Estado | Cómo probar |
|---|---|---|---|
| **F1** | CRUD /clientes + CRU /cuentas /movimientos | ✅ | Requests 1-8 en Postman |
| **F2** | Movimientos +/-, actualiza saldo, registra transacciones | ✅ | Requests 9-12 en Postman |
| **F3** | Saldo no disponible → 400 | ✅ | Request 13 en Postman |
| **F4** | Reporte por fechas y cliente → JSON | ✅ | Requests 14-16 con año 2026 |
| **F5** | Prueba unitaria entidad Cliente | ✅ | `mvn test` → BUILD SUCCESS 6 tests |
| **F6** | Prueba de integración con Testcontainers | ✅ | `mvn test -P integration-test` con Docker activo |
| **F7** | Despliegue en Docker | ✅ | `docker-compose up -d` |

---

## ⚠️ Solución de Problemas

### Problema 1 — Docker Desktop no inicia o interfaz gráfica congelada

Si Docker Desktop tiene problemas con la interfaz gráfica o se congela, **NO es necesario usar la interfaz**. Todo se puede operar desde PowerShell:

```powershell
# Paso 1 — Iniciar Docker Desktop desde consola
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Paso 2 — Esperar que Docker arranque (60 segundos)
Start-Sleep -Seconds 60

# Paso 3 — Verificar que Docker está listo (debe responder sin error)
docker ps

# Paso 4 — Si docker ps responde con la tabla vacía, Docker está listo
# Levantar el sistema directamente desde consola
docker-compose up -d
```

> ⚠️ Si `docker ps` sigue dando error después de 60 segundos, esperar 30 segundos más y repetir.
> La interfaz gráfica de Docker Desktop NO es necesaria en ningún momento — todos los comandos funcionan desde PowerShell.

**Verificar estado de contenedores desde consola:**
```powershell
docker-compose ps
docker logs bp-ms-clientes --tail=10
docker logs bp-ms-cuentas --tail=10
docker logs bp-postgres --tail=10
docker logs bp-rabbitmq --tail=10
```

---

### Problema 2 — RabbitMQ falla con error erlang.cookie o permisos

```powershell
docker-compose down -v
docker container prune -f
docker volume prune -f
docker-compose up -d
```

---

### Problema 3 — Las tablas no se crearon automáticamente

Si `docker exec -it bp-postgres psql -U bpuser -d bpdb -c "\dt"` retorna `Did not find any relations`, crear las tablas manualmente:

**Paso 1 — Conectarse a PostgreSQL:**
```powershell
docker exec -it bp-postgres psql -U bpuser -d bpdb
```

**Paso 2 — Ejecutar el script completo dentro de psql:**
```sql
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

CREATE TABLE IF NOT EXISTS cuentas (
    id              BIGSERIAL       PRIMARY KEY,
    numero_cuenta   VARCHAR(50)     NOT NULL UNIQUE,
    tipo_cuenta     VARCHAR(50)     NOT NULL,
    saldo_inicial   DECIMAL(19,2)   NOT NULL,
    saldo_actual    DECIMAL(19,2)   NOT NULL,
    estado          BOOLEAN         NOT NULL DEFAULT TRUE,
    cliente_id      BIGINT          NOT NULL
);

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
);
```

**Paso 3 — Salir de psql:**
```sql
\q
```

**Paso 4 — Verificar que las 3 tablas existen:**
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

---

### Problema 4 — Primera petición muy lenta (30-60 segundos)

**Es normal.** La primera petición inicializa la conexión a RabbitMQ, el pool de Hikari y la documentación Swagger. A partir de la segunda petición la respuesta es inmediata (menos de 1 segundo).

---

### Problema 5 — Reporte retorna lista vacía []

Verificar que las fechas usen el **año 2026** — los movimientos se registran con la fecha actual del servidor:

```
fechaInicio=2026-01-01T00:00:00
fechaFin=2026-12-31T23:59:59
```

> Juan Osorio siempre retorna `[]` — es correcto porque no tiene movimientos exitosos registrados.

---

### Problema 6 — Contenedor no arranca

Ver los logs del error:
```powershell
docker logs bp-ms-clientes --tail=30
docker logs bp-ms-cuentas --tail=30
```

Reconstruir las imágenes:
```powershell
docker-compose down
docker-compose build --no-cache ms-clientes ms-cuentas
docker-compose up -d
```

---

### Problema 7 — Error 500 en la primera petición

Reintentar la misma petición. El error ocurre porque RabbitMQ aún no terminó de inicializarse. La segunda petición funciona correctamente.

---

## 🛑 Detener el Sistema

```powershell
# Preservar datos
docker-compose down

# Reset completo — elimina todos los datos
docker-compose down -v
```

---

## 📁 Entregables

| Archivo | Descripción |
|---|---|
| `ms-clientes/` | Microservicio CRUD clientes — arquitectura hexagonal |
| `ms-cuentas/` | Microservicio cuentas, movimientos y reportes |
| `docker-compose.yml` | Orquestación completa de 4 servicios |
| `BaseDatos.sql` | Script SQL con esquema completo y datos de prueba |
| `banco-api.postman_collection.json` | Colección con 16 endpoints en orden |
| `ms-clientes/README.md` | Documentación técnica de ms-clientes |
| `ms-cuentas/README.md` | Documentación técnica de ms-cuentas |

Repositorio: https://github.com/jugiros/prueba-tecnica-microservicios-bp

---

## 👤 Autor

**Juan Molina** — Prueba técnica DEVSU / BP

---

## 🎯 Guía de Validación F1 — F7 paso a paso

Esta sección detalla exactamente cómo el evaluador puede probar y verificar cada funcionalidad requerida.

---

### ✅ F1 — CRUD Cliente / CRU Cuenta y Movimiento

**Qué se verifica:** Operaciones completas sobre las tres entidades.

**Cómo probar en Postman:**

| Operación | Método | URL | Body requerido |
|---|---|---|---|
| Crear cliente | POST | `http://localhost:8081/api/clientes` | JSON con datos del cliente |
| Listar clientes | GET | `http://localhost:8081/api/clientes` | — |
| Obtener cliente | GET | `http://localhost:8081/api/clientes/1` | — |
| Actualizar cliente | PUT | `http://localhost:8081/api/clientes/1` | JSON completo |
| Actualizar parcial | PATCH | `http://localhost:8081/api/clientes/1` | JSON con campos a cambiar |
| Eliminar cliente | DELETE | `http://localhost:8081/api/clientes/1` | — |
| Crear cuenta | POST | `http://localhost:8082/api/cuentas` | JSON con datos de cuenta |
| Listar cuentas | GET | `http://localhost:8082/api/cuentas` | — |
| Actualizar cuenta | PUT | `http://localhost:8082/api/cuentas/1` | JSON completo |
| Registrar movimiento | POST | `http://localhost:8082/api/movimientos` | `{ "valor": X, "cuentaId": Y }` |
| Obtener movimiento | GET | `http://localhost:8082/api/movimientos/1` | — |

**Resultado esperado:** Cada operación retorna el status HTTP correcto — 201 para creación, 200 para consulta y actualización, 204 para eliminación.

---

### ✅ F2 — Registro de movimientos con actualización de saldo

**Qué se verifica:** Valores positivos y negativos, saldo actualizado tras cada movimiento.

**Cómo probar:**

```
POST http://localhost:8082/api/movimientos
Body: { "valor": -575.00, "cuentaId": 1 }   → Retiro  → saldo pasa de 2000 a 1425
Body: { "valor":  600.00, "cuentaId": 2 }   → Depósito → saldo pasa de 100 a 700
Body: { "valor":  150.00, "cuentaId": 3 }   → Depósito → saldo pasa de 0 a 150
Body: { "valor": -540.00, "cuentaId": 4 }   → Retiro  → saldo pasa de 540 a 0
```

**Verificar en base de datos:**
```powershell
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "SELECT * FROM movimientos;"
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "SELECT numero_cuenta, saldo_actual FROM cuentas;"
```

---

### ✅ F3 — Saldo no disponible

**Qué se verifica:** Sistema rechaza retiro cuando saldo es insuficiente con mensaje exacto.

**Cómo probar:**
```
POST http://localhost:8082/api/movimientos
Body: { "valor": -1000.00, "cuentaId": 3 }
```

Cuenta 3 tiene saldo 150 — retiro de 1000 supera el saldo disponible.

**Resultado esperado:**
```json
HTTP 400 Bad Request
{ "mensaje": "Saldo no disponible" }
```

---

### ✅ F4 — Reporte Estado de Cuenta

**Qué se verifica:** Reporte por rango de fechas y cliente retorna JSON con cuentas y movimientos.

**Cómo probar:**
```
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=1
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=2
GET http://localhost:8082/api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=3
```

> ⚠️ Usar **año 2026** — los movimientos se registran con la fecha actual del servidor.

**Resultado esperado:**
- clienteId=1 → JSON con movimientos de Jose Lema
- clienteId=2 → JSON con movimientos de Marianela
- clienteId=3 → `[]` — Juan Osorio no tiene movimientos válidos — **correcto**

---

### ✅ F5 — Pruebas Unitarias

**Qué se verifica:** 6 pruebas JUnit 5 + Mockito sobre la entidad Cliente pasan sin errores.

**Cómo probar:**
```powershell
cd ms-clientes
mvn test
```

**Resultado esperado:**
```
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

---

### ✅ F6 — Prueba de Integración con Testcontainers

**Qué se verifica:** 5 pruebas de integración que levantan PostgreSQL real en Docker y prueban el endpoint `/api/clientes` completo end-to-end.

**Requisito:** Docker Desktop debe estar activo.

**Cómo probar:**
```powershell
cd ms-clientes
mvn test -P integration-test
```

**Resultado esperado:**
```
Tests run: 5, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

**Por qué usa perfil separado:** Docker Desktop en Windows usa Named Pipes que Maven no puede acceder sin configuración adicional del sistema. El perfil `integration-test` permite ejecutar F6 cuando Docker está disponible sin romper el build normal `mvn test`.

---

### ✅ F7 — Despliegue en Docker

**Qué se verifica:** Sistema completo levanta con un solo comando.

**Cómo probar:**
```powershell
# Desde la raíz del proyecto
docker-compose up -d

# Verificar 4 contenedores healthy
docker-compose ps

# Verificar 3 tablas creadas
docker exec -it bp-postgres psql -U bpuser -d bpdb -c "\dt"
```

**Resultado esperado:**
```
bp-postgres      Up (healthy)
bp-rabbitmq      Up (healthy)
bp-ms-clientes   Up (healthy)
bp-ms-cuentas    Up (healthy)

clientes    ✅
cuentas     ✅
movimientos ✅
```
