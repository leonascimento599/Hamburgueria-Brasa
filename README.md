# Brasa & Ponto — Flutter Web + Dart Frog

Projeto demonstrativo de uma hamburgueria/delivery. O design usa a organização e a navegação por categorias como referência do Bob's e uma direção visual de fotografia gastronômica mais quente, saturada e contrastada inspirada na experiência do Burger King. A identidade, os textos e a marca são fictícios; não foram copiados logotipos.

## O que está implementado

- Cardápio interativo com busca textual e categorias.
- Destaque de novidades/itens populares e cards com fotos.
- Favoritos por sessão.
- Montagem de burger com adicionais pagos e remoção de ingredientes.
- Sacola com alteração de quantidade, subtotal, taxa de entrega e desconto `BRASA10`.
- Checkout demonstrativo com nome, endereço e modalidade de pagamento na entrega.
- Criação de pedido na API e tela de rastreio com atualização automática a cada 8 segundos.
- Layout responsivo para desktop e celular.
- Fallback de cardápio local quando a API ainda não estiver conectada.
- API para cardápio, cupons, criação e consulta de pedidos.

## Estrutura

```text
brasa_ponto_app/
├── frontend/              # Flutter Web
│   ├── lib/
│   │   ├── data/          # Cardápio local de fallback e adicionais
│   │   ├── models/        # Produto, adicional e item da sacola
│   │   ├── screens/       # Loja, personalização, checkout e rastreio
│   │   ├── services/     # Cliente HTTP para a API
│   │   └── main.dart
│   └── web/index.html
└── backend/               # API Dart Frog
    ├── lib/               # Dados do menu e armazenamento demonstrativo
    └── routes/            # Endpoints REST
```

## Pré-requisitos

- Flutter SDK com suporte a Web habilitado.
- Dart SDK (já vem com o Flutter).
- Dart Frog CLI.

Instalação da CLI (uma vez):

```bash
dart pub global activate dart_frog_cli
```

Garanta que o diretório de executáveis globais do Dart esteja no `PATH`.

## Executar localmente

### 1. Iniciar a API

Em um terminal:

```bash
cd backend
dart pub get
dart_frog dev
```

A API fica disponível em `http://localhost:8080`.

### 2. Iniciar o Flutter Web

Em outro terminal:

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Para gerar os arquivos web de produção:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://SUA-API.example.com
```

Hospede o conteúdo de `frontend/build/web` em um servidor estático e publique a API em uma origem HTTPS. Em produção, ajuste CORS para permitir somente o domínio real do frontend, em vez de `*`.

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| `GET` | `/` | Health check e lista de rotas |
| `GET` | `/menu` | Produtos, categorias, adicionais e cupons |
| `GET` | `/coupons` | Cupons disponíveis |
| `POST` | `/orders` | Cria um pedido e calcula os valores no servidor |
| `GET` | `/orders/:id` | Consulta status, previsão e etapas do pedido |

Exemplo de criação de pedido:

```bash
curl -X POST http://localhost:8080/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "customerName": "Ana",
    "address": "Rua das Flores, 123, Centro",
    "paymentMethod": "Pix na entrega",
    "coupon": "BRASA10",
    "items": [
      {
        "productId": "brasa-classico",
        "quantity": 1,
        "extras": ["bacon", "cheddar"],
        "removedIngredients": ["Sem cebola"]
      }
    ]
  }'
```

A resposta contém o identificador `BP-XXXXXX`, que deve ser usado em `GET /orders/BP-XXXXXX`.

## Observações importantes antes de produção

Este é um starter funcional para desenvolvimento/apresentação, não um sistema de pedidos pronto para operação comercial.

1. **Persistência:** os pedidos ficam em memória no processo Dart Frog e são perdidos ao reiniciar o servidor. Troque `OrderStore` por PostgreSQL/Firestore e operações transacionais.
2. **Status:** a linha do tempo avança por tempo decorrido apenas para demonstrar o rastreio. Integre os eventos reais da cozinha e do entregador.
3. **Pagamento:** não há gateway nem cobrança real. O checkout só registra a modalidade que será paga na entrega; integre um provedor com backend seguro antes de aceitar pagamentos online.
4. **Entrega:** a taxa e a previsão são regras ilustrativas. Calcule frete e ETA por área, distância e capacidade operacional.
5. **Segurança:** adicione autenticação/autorização administrativa, rate limiting, validação de endereço, logs, observabilidade, proteção contra abuso e política de privacidade. Restrinja CORS ao domínio publicado.
6. **Imagens:** as fotos vêm de URLs externas do Unsplash e exigem conexão com a internet. Substitua por imagens licenciadas da própria marca antes de publicar.
7. **Preços:** a API recalcula preço dos produtos e adicionais usando o catálogo do servidor; não confia em valores enviados pelo navegador.

## Ajustes rápidos

- Produtos, preços e imagens: `backend/lib/menu_data.dart` e `frontend/lib/data/demo_menu.dart`.
- Adicionais disponíveis: lista `addOns` do backend e `extraChoices` do frontend.
- Endereço da API no build: `--dart-define=API_BASE_URL=...`.
- Cores principais: `_ink`, `_ember`, `_gold` em `frontend/lib/screens/home_page.dart` e tema em `frontend/lib/main.dart`.
