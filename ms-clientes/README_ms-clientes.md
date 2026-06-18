# ms-clientes

Microservicio responsable del ciclo de vida completo de clientes del banco.

---

## Responsabilidad

- CRUD completo de clientes (`/api/clientes`)
- Publica eventos a RabbitMQ cuando un cliente es creado
- Puerto: **8081**

---

## Tecnologías

| Tecnología | Uso |
|---|---|
| Java 21 | Lenguaje base |
| Spring Boot 4.1.0 | Framework principal |
| Spring Data JPA | Persistencia con PostgreSQL |
| Spring AMQP | Publicación de eventos a RabbitMQ |
| MapStruct | Conversión entre capas |
| Lombok | Reducción de boilerplate |
| SpringDoc OpenAPI | Documentación Swagger automática |
| JUnit 5 + Mockito | Pruebas unitarias |

---

## Arquitectura Hexagonal

```
ms-clientes/
└── src/main/java/com/bp/msclientes/
    ├── domain/
    │   ├── model/
    │   │   ├── Persona.java          ← Clase base con atributos comunes
    │   │   └── Cliente.java          ← Entidad de dominio pura (hereda Persona)
    │   ├── port/
    │   │   ├── in/                   ← Casos de uso (interfaces)
    │   │   │   ├── CrearClienteUseCase.java
    │   │   │   ├── ObtenerClienteUseCase.java
    │   │   │   ├── ActualizarClienteUseCase.java
    │   │   │   └── EliminarClienteUseCase.java
    │   │   └── out/
    │   │       └── ClienteRepositoryPort.java  ← Puerto de salida
    │   └── service/
    │       └── ClienteService.java   ← Lógica de negocio
    ├── infrastructure/
    │   ├── adapter/
    │   │   ├── in/rest/
    │   │   │   └── ClienteController.java      ← Adaptador HTTP
    │   │   └── out/
    │   │       ├── persistence/
    │   │       │   ├── ClienteEntity.java
    │   │       │   ├── ClienteJpaRepository.java
    │   │       │   └── ClienteRepositoryAdapter.java
    │   │       └── messaging/
    │   │           └── ClienteEventPublisher.java
    │   └── config/
    │       ├── RabbitMQConfig.java
    │       └── SwaggerConfig.java
    └── shared/
        ├── dto/
        │   ├── ClienteRequestDTO.java
        │   └── ClienteResponseDTO.java
        ├── mapper/
        │   └── ClienteMapper.java
        └── exception/
            ├── GlobalExceptionHandler.java
            ├── ClienteNotFoundException.java
            └── BusinessException.java
```

---

## Endpoints

| Método | Endpoint | Descripción | Status |
|---|---|---|---|
| POST | `/api/clientes` | Crear cliente | 201 |
| GET | `/api/clientes` | Listar todos | 200 |
| GET | `/api/clientes/{id}` | Obtener por ID | 200 |
| PUT | `/api/clientes/{id}` | Actualizar completo | 200 |
| PATCH | `/api/clientes/{id}` | Actualizar parcial | 200 |
| DELETE | `/api/clientes/{id}` | Eliminar | 204 |

Swagger UI: http://localhost:8081/swagger-ui.html

---

## Modelo de datos

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

---

## Eventos RabbitMQ publicados

| Exchange | Queue | Routing Key | Cuándo |
|---|---|---|---|
| `clientes.exchange` | `cliente.creado.queue` | `cliente.creado` | POST /api/clientes exitoso |

---

## Pruebas unitarias

```bash
cd ms-clientes
mvn test
```

6 pruebas — BUILD SUCCESS:
- `crearCliente_exitoso`
- `crearCliente_identificacionDuplicada`
- `obtenerClientePorId_existente`
- `obtenerClientePorId_noEncontrado`
- `actualizarCliente_exitoso`
- `MsClientesApplicationTests` (contexto)

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
| `SERVER_PORT` | `8081` | `8081` |

---

## Ejecutar localmente (sin Docker)

Requiere PostgreSQL y RabbitMQ corriendo localmente:

```bash
cd ms-clientes
mvn clean package -DskipTests
java -jar target/ms-clientes-0.0.1-SNAPSHOT.jar
```
