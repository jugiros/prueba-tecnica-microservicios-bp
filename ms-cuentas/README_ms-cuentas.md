# ms-cuentas

Microservicio responsable de cuentas bancarias, movimientos y reportes de estado de cuenta.

---

## Responsabilidad

- CRU de cuentas bancarias (`/api/cuentas`)
- CRU de movimientos bancarios (`/api/movimientos`)
- Reporte F4 por rango de fechas y cliente (`/api/reportes`)
- Valida saldo disponible — lanza error 400 si no hay fondos
- Consume eventos de RabbitMQ publicados por ms-clientes
- Llama a ms-clientes via HTTP para enriquecer reportes
- Puerto: **8082**

---

## Tecnologías

| Tecnología | Uso |
|---|---|
| Java 21 | Lenguaje base |
| Spring Boot 4.1.0 | Framework principal |
| Spring Data JPA | Persistencia con PostgreSQL |
| Spring AMQP | Consumo de eventos de RabbitMQ |
| RestClient (Spring Boot 4.x) | Comunicación HTTP con ms-clientes |
| MapStruct | Conversión entre capas |
| Lombok | Reducción de boilerplate |
| SpringDoc OpenAPI | Documentación Swagger automática |

---

## Arquitectura Hexagonal

```
ms-cuentas/
└── src/main/java/com/bp/mscuentas/
    ├── domain/
    │   ├── model/
    │   │   ├── Cuenta.java           ← Entidad de dominio
    │   │   └── Movimiento.java       ← Entidad de dominio
    │   ├── port/
    │   │   ├── in/                   ← Casos de uso
    │   │   └── out/                  ← Puertos de salida
    │   └── service/
    │       ├── CuentaMovimientoService.java  ← Lógica crítica de saldos
    │       └── ReporteService.java           ← Generación de reporte F4
    ├── infrastructure/
    │   ├── adapter/
    │   │   ├── in/rest/
    │   │   │   ├── CuentaController.java
    │   │   │   ├── MovimientoController.java
    │   │   │   └── ReporteController.java
    │   │   └── out/
    │   │       ├── persistence/
    │   │       │   ├── CuentaEntity.java
    │   │       │   ├── MovimientoEntity.java
    │   │       │   ├── CuentaJpaRepository.java
    │   │       │   ├── MovimientoJpaRepository.java
    │   │       │   ├── CuentaRepositoryAdapter.java
    │   │       │   └── MovimientoRepositoryAdapter.java
    │   │       ├── feign/
    │   │       │   └── ClienteRestClient.java  ← HTTP hacia ms-clientes
    │   │       └── messaging/
    │   │           └── ClienteEventConsumer.java
    │   └── config/
    │       ├── RabbitMQConfig.java
    │       └── SwaggerConfig.java
    └── shared/
        ├── dto/
        │   ├── CuentaRequestDTO.java
        │   ├── CuentaResponseDTO.java
        │   ├── MovimientoRequestDTO.java
        │   ├── MovimientoResponseDTO.java
        │   └── ReporteDTO.java
        ├── mapper/
        │   ├── CuentaMapper.java
        │   └── MovimientoMapper.java
        └── exception/
            ├── GlobalExceptionHandler.java
            ├── CuentaNotFoundException.java
            └── SaldoInsuficienteException.java
```

---

## Endpoints

| Método | Endpoint | Descripción | Status |
|---|---|---|---|
| POST | `/api/cuentas` | Crear cuenta | 201 |
| GET | `/api/cuentas` | Listar todas | 200 |
| GET | `/api/cuentas/{id}` | Obtener por ID | 200 |
| PUT | `/api/cuentas/{id}` | Actualizar completa | 200 |
| PATCH | `/api/cuentas/{id}` | Actualizar parcial | 200 |
| POST | `/api/movimientos` | Registrar movimiento | 201 |
| GET | `/api/movimientos/{id}` | Obtener por ID | 200 |
| PUT | `/api/movimientos/{id}` | Actualizar movimiento | 200 |
| GET | `/api/reportes` | Reporte F4 por fechas y cliente | 200 |

Swagger UI: http://localhost:8082/swagger-ui.html

---

## Lógica de movimientos (F2 y F3)

- Valor **positivo** → Depósito → suma al saldo actual
- Valor **negativo** → Retiro → resta del saldo actual
- Si `saldo actual < |valor retiro|` → **400 Bad Request**

```json
{ "mensaje": "Saldo no disponible" }
```

---

## Reporte F4

```
GET /api/reportes?fechaInicio=2026-01-01T00:00:00&fechaFin=2026-12-31T23:59:59&clienteId=1
```

Respuesta:
```json
[{
  "fecha": "2026-06-18",
  "cliente": "Jose Lema",
  "numeroCuenta": "478758",
  "tipo": "Ahorros",
  "saldoInicial": 2000.00,
  "estado": true,
  "movimiento": -575.00,
  "saldoDisponible": 1425.00
}]
```

> ⚠️ Usar el año actual en fechaInicio y fechaFin. Los movimientos se registran con la fecha del servidor.

---

## Comunicación con ms-clientes

ms-cuentas llama a ms-clientes via HTTP para obtener el nombre del cliente en el reporte:

| Contexto | URL |
|---|---|
| Docker | `http://ms-clientes:8081` |
| Local | `http://localhost:8081` |

Configurado en `application.yaml`:
```yaml
ms-clientes:
  url: ${MS_CLIENTES_URL:http://localhost:8081}
```

---

## Eventos RabbitMQ consumidos

| Queue | Qué hace al recibirlo |
|---|---|
| `cliente.creado.queue` | Registra log de cliente creado en ms-cuentas |

---

## Variables de entorno

| Variable | Valor Docker | Valor por defecto |
|---|---|---|
| `DB_HOST` | `postgres` | `localhost` |
| `DB_PORT` | `5432` | `5432` |
| `DB_NAME` | `bpdb` | `bpdb` |
| `DB_USER` | `bpuser` | `bpuser` |
| `DB_PASSWORD` | `bppassword` | `bppassword` |
| `RABBITMQ_HOST` | `rabbitmq` | `localhost` |
| `MS_CLIENTES_URL` | `http://ms-clientes:8081` | `http://localhost:8081` |
| `SERVER_PORT` | `8082` | `8082` |

---

## Ejecutar localmente (sin Docker)

Requiere ms-clientes, PostgreSQL y RabbitMQ corriendo:

```bash
cd ms-cuentas
mvn clean package -DskipTests
java -jar target/ms-cuentas-0.0.1-SNAPSHOT.jar
```
