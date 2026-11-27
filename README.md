# Brasa & Ponto

Projeto demonstrativo de uma hamburgueria com delivery. O design usa a organização e a navegação por categorias como referência do Bob's e a fotografia gastronômica como referência do Burger King. A identidade, os textos e a marca são fictícios.

## Funcionalidades

- Cardápio com busca, categorias, destaques e favoritos por sessão.
- Personalização com adicionais por produto e remoção de ingredientes em burgers e combos.
- Sacola com vários produtos, ajuste de quantidade, cupom e opção de continuar comprando.
- Checkout demonstrativo com nome, endereço e forma de pagamento na entrega.
- Pedidos salvos no Supabase e rastreio por código, com atualização a cada 8 segundos enquanto a janela está aberta e o pedido ainda está em andamento.
- Layout responsivo e temas claro e escuro. O site segue o tema do aparelho na primeira visita e guarda a escolha no navegador.

O rastreio simula as etapas pelo tempo decorrido. O checkout registra a forma de pagamento escolhida para a entrega.

## Arquitetura

O Flutter Web chama as rotas `/api` no próprio domínio do site. A Vercel hospeda o frontend e executa as funções Node.js, que consultam o catálogo e gravam pedidos no PostgreSQL pela API REST do Supabase.

```text
frontend/
├── lib/
│   ├── app_theme.dart        # Temas claro e escuro
│   ├── main.dart             # Inicialização e preferência de tema
│   ├── models/               # Catálogo, produtos e sacola
│   ├── screens/              # Loja, checkout e rastreio
│   └── services/api_service.dart
├── test/                     # Testes de tema e navegação da sacola
└── web/
backend/
├── api/                      # Rotas públicas da Vercel
├── server/                   # Catálogo, pedidos e acesso ao Supabase
├── lib/                      # Catálogo local e persistência da API Dart Frog
├── routes/                   # Rotas locais do Dart Frog
├── package.json              # Script vercel-build
└── vercel.json               # Build estático, funções Node e rotas
```

## Supabase

No painel do Supabase, obtenha a **Project URL** em **Connect** e a chave secreta em **Settings → API Keys**. Guarde o valor da chave nas variáveis de ambiente do backend e mantenha-o fora do Git e do código Flutter. [Chaves de API do Supabase](https://supabase.com/docs/guides/getting-started/api-keys)

| Variável | Valor |
| --- | --- |
| `SUPABASE_URL` | URL base HTTPS do projeto, como `https://seu-projeto.supabase.co` |
| `SUPABASE_SECRET_KEY` | Chave secreta do mesmo projeto, do tipo `sb_secret_…` |

### Tabelas

| Tabela em `public` | Chave | Dados |
| --- | --- | --- |
| `catalog_categories` | `id` | `data` com `id` e `name` |
| `catalog_products` | `id` | `data` com `id`, `name`, `category`, `price`, `description`, `image` e campos opcionais como `allowedAddOnIds` |
| `catalog_add_ons` | `id` | `data` com `id`, `name` e `price` |
| `catalog_coupons` | `code` | `data` com `code`, `description` e `discountPercent` |
| `orders` | `id` | `payload` com itens, totais, endereço e data de criação |

As quatro tabelas do catálogo usam chave primária `text`, `position integer`, `active boolean` (padrão `true`) e `data jsonb`. Em um projeto Supabase novo, crie essas tabelas e importe os dados iniciais antes do deploy. Para `orders`, uma definição mínima compatível com o backend é `id text primary key` e `payload jsonb not null`. Em uma base existente, confira as colunas no **Table Editor**.

Habilite **RLS** nas tabelas e restrinja o acesso direto dos papéis `anon` e `authenticated`. As funções usam `service_role` com leitura do catálogo e leitura e inserção em `orders`. [RLS e privilégios no Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security)

### Editar o cardápio

Use o **Table Editor** para editar `data` ou o **SQL Editor** para alterações pontuais. A API exibe registros com `active = true` em ordem de `position`. Recarregue o site para buscar os dados atualizados.

- Mantenha a chave da linha igual ao `id` ou `code` dentro de `data`.
- Em um produto, use o nome da categoria em `data.category` e informe o preço como número.
- Em `data.allowedAddOnIds`, liste IDs de adicionais ativos. Uma lista vazia desativa os adicionais para aquele produto. Quando o campo está ausente, a API aplica a lista padrão definida em [catalog.js](backend/server/catalog.js).
- Para retirar um produto do cardápio, altere `active` para `false`.

## Executar localmente

Instale o Flutter SDK com suporte à Web e use o Chrome para abrir o app. Para iniciar a API local, instale a CLI uma vez com `dart pub global activate dart_frog_cli` e deixe o executável `dart_frog` no PATH.

Em um PowerShell, a partir da raiz do repositório, defina as credenciais do Supabase para salvar e consultar pedidos:

```powershell
cd backend
$env:SUPABASE_URL = "https://seu-projeto.supabase.co"
$chaveSupabase = Read-Host "Cole a chave secreta" -AsSecureString
$credencialSupabase = [System.Net.NetworkCredential]::new("", $chaveSupabase)
$env:SUPABASE_SECRET_KEY = $credencialSupabase.Password
dart pub get
dart_frog dev
```

Abra outro PowerShell na raiz do repositório e inicie o Flutter:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

O Dart Frog serve o catálogo de desenvolvimento a partir de [menu_data.dart](backend/lib/menu_data.dart). Para testar o catálogo do Supabase e as rotas Node.js, use um deploy da Vercel.

## Publicar na Vercel

1. Importe o repositório do GitHub na Vercel e selecione `main` como branch de produção.
2. Em **Settings → Build and Deployment**, use **Other** como preset e **backend** em **Root Directory**. Deixe **Include files outside the root directory in the Build Step** habilitado para o build acessar `../frontend`. [Configuração do build na Vercel](https://vercel.com/docs/builds/configure-a-build)
3. Adicione `SUPABASE_URL` e `SUPABASE_SECRET_KEY` em **Environment Variables** no ambiente **Production**. Configure **Preview** se precisar testar publicações de prévia. Depois de cadastrar ou alterar variáveis, faça um novo deploy. [Variáveis de ambiente na Vercel](https://vercel.com/docs/environment-variables)
4. Confira o commit e os **Build Logs** na aba **Deployments**. O script `vercel-build` compila o Flutter com `--dart-define=API_BASE_URL=/api` e copia a saída para `backend/public`. A configuração publica os arquivos web e as funções Node.js. [package.json](backend/package.json) · [vercel.json](backend/vercel.json)
5. Abra `/api/menu` no domínio publicado e confira se a resposta contém os produtos. Faça um pedido de teste pelo site, confirme o registro em `orders` e consulte o código na tela de rastreio.

Se `/api/menu` devolver uma página 404, verifique se o deploy usa o commit correto e encontrou o `vercel.json` em `backend`. Para HTTP 503, confira os logs da função, as variáveis e as tabelas do projeto Supabase.

## Rotas em produção

| Método | Rota | Função |
| --- | --- | --- |
| `GET` | `/api/menu` | Retorna produtos, categorias, adicionais e cupons ativos |
| `GET` | `/api/coupons` | Lista os cupons ativos |
| `POST` | `/api/orders` | Valida o pedido, recalcula os valores e salva no Supabase |
| `GET` | `/api/orders/{id}` | Retorna status, previsão e etapas do pedido |

O checkout devolve um código com seis caracteres hexadecimais após `BP-`, como `BP-A3F921`. A rota de rastreio também aceita os códigos anteriores com 16 caracteres.

## Testes

Execute na pasta `frontend`. Os testes cobrem a troca de tema e o retorno da sacola ao cardápio para adicionar outro produto.

```powershell
flutter test
```
