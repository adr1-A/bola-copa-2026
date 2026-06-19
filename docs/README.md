# Bolão Copa 2026 - Documentação

## 📋 Visão Geral

**Bolão Copa 2026** é uma aplicação web moderna para gerenciar bolões da Copa do Mundo 2026 com:
- Interface intuitiva e responsiva
- Sistema automático de pontuação
- Ranking em tempo real
- Backend robusto com Azure Functions
- Banco de dados SQL Server

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                    Azure Services                   │
├─────────────────────────────────────────────────────┤
│  Frontend (React) ─────→  Azure Static Web App      │
│  Backend (Functions) ───→  Azure Functions          │
│  Database ────────────→  Azure SQL Database         │
└─────────────────────────────────────────────────────┘
```

## 🚀 Como Funciona

### Sistema de Pontuação
- **3 pontos**: Acerta o placar exato (ex: 2x1)
- **1 ponto**: Acerta apenas o resultado (vencedor ou empate)
- **0 pontos**: Erra o resultado

### Exemplo de Cálculo
Se o jogo real foi **México 1x0 Coreia**:
- Palpite 1x0: **3 pontos** ✅ (placar exato)
- Palpite 2x0: **1 ponto** ✅ (acertou que México vence)
- Palpite 0x1: **0 pontos** ❌ (errou o resultado)

## 📦 Stack Tecnológico

### Backend
- **.NET 8** - Framework moderno
- **Azure Functions** - Serverless computing
- **SQL Server** - Banco de dados
- **C#** - Linguagem de programação

### Frontend
- **React 18** - Framework UI
- **TypeScript** - Tipagem segura
- **Tailwind CSS** - Estilização
- **Axios** - HTTP client

## 🔧 Instalação Local

### Pré-requisitos
- Node.js 18+
- .NET 8 SDK
- Azure CLI (para deploy)
- SQL Server (local ou Azure)

### Backend

```bash
cd backend

# Instalar dependências
dotnet restore

# Configurar local.settings.json com sua connection string
# Editar: local.settings.json

# Rodar localmente
func start
```

Backend rodará em `http://localhost:7071`

### Frontend

```bash
cd frontend

# Instalar dependências
npm install

# Variáveis de ambiente
echo "REACT_APP_API_URL=http://localhost:7071/api" > .env

# Rodar em desenvolvimento
npm start
```

Frontend rodará em `http://localhost:3000`

## 📊 Banco de Dados

### Criar Schema

Execute o arquivo `database/schema.sql` em seu SQL Server:

```sql
-- Conectar ao SQL Server
sqlcmd -S your_server -U your_user -P your_password

-- Executar script
:r database/schema.sql
```

### Tabelas Principais

1. **Tournaments** - Competições
2. **Phases** - Fases (Rodada 1, Rodada 2, etc)
3. **Matches** - Jogos específicos
4. **Participants** - Participantes do bolão
5. **Guesses** - Palpites dos participantes
6. **Rankings** - Placar desnormalizado

## 🌐 Deploy no Azure

### 1. Preparar Recursos

```bash
# Login no Azure
az login

# Criar resource group
az group create --name bolao-copa-2026 --location eastus

# Criar Storage Account
az storage account create --resource-group bolao-copa-2026 \
  --name bolaocopa2026 --location eastus

# Criar Function App
az functionapp create --resource-group bolao-copa-2026 \
  --consumption-plan-location eastus \
  --runtime dotnet-isolated --runtime-version 8.0 \
  --functions-version 4 \
  --name bolao-copa-2026-api
```

### 2. Deploy Backend

```bash
cd backend

# Fazer build
dotnet publish -c Release -o bin/Release/publish

# Deploy com Azure Functions Core Tools
func azure functionapp publish bolao-copa-2026-api
```

### 3. Deploy Frontend

```bash
cd frontend

# Build
npm run build

# Deploy para Static Web App
az staticwebapp create --resource-group bolao-copa-2026 \
  --name bolao-copa-2026-web \
  --source ./build
```

## 📝 Variáveis de Ambiente

### Backend (local.settings.json)
```json
{
  "SqlConnectionString": "Server=tcp:YOUR_SERVER.database.windows.net;Initial Catalog=BolaoCopa2026;Persist Security Info=False;User ID=YOUR_USER;Password=YOUR_PASSWORD;Encrypt=True;",
  "AllowedOrigins": "https://localhost:3000,https://your-domain.com"
}
```

### Frontend (.env)
```
REACT_APP_API_URL=https://bolao-copa-2026-api.azurewebsites.net/api
```

## 🔌 API Endpoints

### Matches
- `GET /api/phases/{phaseId}/matches` - Obter jogos de uma fase

### Ranking
- `GET /api/tournaments/{tournamentId}/ranking` - Obter ranking completo

### Guesses
- `POST /api/guesses` - Registrar um palpite
  ```json
  {
    "participantId": "uuid",
    "matchId": "uuid",
    "homeTeamScore": 2,
    "awayTeamScore": 1
  }
  ```

## 📱 Features

✅ Listagem de jogos por rodada/fase
✅ Formulário intuitivo para palpites
✅ Cálculo automático de pontos
✅ Ranking em tempo real
✅ Interface responsiva (mobile-friendly)
✅ Validação de dados
✅ Histórico de palpites

## 🛣️ Roadmap

- [ ] Autenticação de usuários
- [ ] Upload de logotipos de times
- [ ] Notificações em tempo real
- [ ] Chat entre participantes
- [ ] Estatísticas avançadas
- [ ] App mobile nativo

## 🐛 Troubleshooting

### Erro de conexão ao banco de dados
- Verificar connection string
- Verificar firewall SQL Server
- Verificar credenciais

### Frontend não conecta ao Backend
- Verificar CORS settings
- Verificar URL da API
- Verificar se Backend está rodando

### Erros de deploy
- Verificar versão do .NET
- Verificar credenciais do Azure
- Consultar logs do Azure

## 📞 Suporte

Para problemas ou sugestões, abra uma issue no repositório.

## 📄 Licença

MIT License - veja LICENSE.md para detalhes.

---

**Desenvolvido com ❤️ para os fãs de futebol**
