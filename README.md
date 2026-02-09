# Order Service (Rails 8.1 / Ruby 3.4)

Microservicio responsable de crear pedidos y consultarlos por `customer_id`.
Al crear un pedido:
1) Consulta datos del cliente vía HTTP al `customer-service`.
2) Publica un evento `order.created` en RabbitMQ.

## Stack
- Ruby 3.4.x
- Rails 8.1.x
- PostgreSQL 16
- RabbitMQ 3 (provisto por customer-service)

---

## Requisitos
- Docker + Docker Compose (v2)

Este repositorio levanta su propia DB + API, pero depende de que `customer-service` esté corriendo
(para RabbitMQ y para el endpoint de clientes).

---

## Arquitectura y flujo

### Responsabilidad
- **API (order-web):** crear pedidos y consultarlos por `customer_id`.
- **Integración HTTP:** al crear una orden, obtiene `customer_name y address` desde `customer-service` y los persiste como snapshot.
- **Publicación de eventos:** publica `order.created` tras crear el pedido para notificar a otros servicios.

### Flujo general
```
POST /orders
  -> CustomerService::Client (HTTP GET /customers/:id)
  -> persist Order (Postgres)
  -> publish event (RabbitMQ: orders exchange, routing_key order.created)
```

### Decisiones de diseño (patrones / SOLID)
- **Use case / Application Service:** `Orders::Create` orquesta el caso de uso (SRP).
- **Adapters:** `CustomerService::Client` (HTTP) y `Orders::Publishers::*` (RabbitMQ) encapsulan infraestructura.
- **DIP (Dependency Inversion):** `Orders::Create` recibe `customer_client` y `publisher` por inyección, facilitando pruebas con doubles.
- **Contrato de evento:** payload incluye `event_id`, `event_type`, `occurred_at` y `order` (datos mínimos para consumidores).

---


## Red compartida (para comunicación entre repositorios)
Crear una sola vez:

```bash
docker network create monokera-shared
```

---

## Ejecutar el servicio (Docker)

### 1) Levantar primero `customer-service` (Omitir si ya se encuentra corriendo)
En el repositorio `customer-service/`:
```bash
docker compose up --build
```

### 2) Levantar `order-service`
En este repositorio:
```bash
docker compose up --build
```

### Servicios expuestos
- API (order-web): http://localhost:3002
- PostgreSQL: localhost:5434

---

## Endpoints

### Crear orden
```bash
curl -i -X POST http://localhost:3002/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "customer_id": 1,
      "product_name": "Mouse",
      "quantity": 1,
      "price": 50000,
      "status": "paid"
    }
  }'
```

### Consultar órdenes por customer_id
```bash
curl -i "http://localhost:3002/api/v1/orders?customer_id=1"
```

---

## Verificación end-to-end del flujo completo solicitado (HTTP + RabbitMQ)

1) Asegura que el cliente exista:
```bash
curl -i http://localhost:3001/api/v1/customers/1
```

2) Crea una orden:
```bash
curl -i -X POST http://localhost:3002/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{"order":{"customer_id":1,"product_name":"Keyboard","quantity":1,"price":1000,"status":"paid"}}'
```

3) Verifica que el customer-service incrementó `orders_count` (por evento):
```bash
curl -i http://localhost:3001/api/v1/customers/1
```

---


## Testing Strategy
La estrategia de pruebas cubre endpoints, use cases y la comunicación entre microservicios sin depender de RabbitMQ real en cada prueba.

- **Request specs (API)**: validan la creación y consulta de pedidos.
  - Ejemplos: `POST /api/v1/orders` (201/422) y `GET /api/v1/orders?customer_id=` (200/400).
- **Unit specs (use case)**: validan `Orders::Create` como orquestador:
  - Llama al `CustomerService::Client` (se stubbea la respuesta HTTP para aislar la prueba).
  - Persiste la orden con datos del cliente (snapshot: `customer_name`/`address`).
  - Publica el evento `order.created` (se verifica `publisher.publish(payload)` y el shape mínimo del payload).
- **Errores controlados**: si falla `customer-service`, el use case no crea orden ni publica evento (evita side-effects).

Comando para ejecutar las pruebas:

```
rspec spec/
```

---

## Troubleshooting

### POST /orders falla por customer-service caído
Es esperado: el flujo requiere consultar el cliente al crear pedido.
Asegúrate de que `customer-web` esté corriendo.
