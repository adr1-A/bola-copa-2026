# ⚽ Bolão Copa 2026

Aplicação web moderna e completa para gerenciar bolões da **Copa do Mundo 2026** com sistema automático de pontuação, ranking em tempo real e interface intuitiva.

![Status](https://img.shields.io/badge/status-active-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Azure](https://img.shields.io/badge/hosting-Azure-blue)

## 🎯 Objetivo

Facilitar o gerenciamento de bolões de futebol com:
- ✅ Sistema de pontuação automático (3 pts placar exato, 1 pt vencedor)
- ✅ Ranking em tempo real
- ✅ Interface intuitiva e responsiva
- ✅ Suporte a múltiplas rodadas/fases
- ✅ Hospedagem serverless na Azure

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────┐
│          Bolão Copa 2026                │
├─────────────────────────────────────────┤
│                                         │
│  Frontend (React + TypeScript)          │
│  ├─ App.tsx (componente principal)      │
│  ├─ Tailwind CSS (estilização)          │
│  └─ Axios (HTTP client)                 │
│                                         │
│  API (.NET 8 + Azure Functions)         │
│  ├─ GetPhaseMatches                     │
│  ├─ GetRanking                          │
│  └─ SaveGuess                           │
│                                         │
│  Database (SQL Server)                  │
│  ├─ Tournaments                         │
│  ├─ Phases                              │
│  ├─ Matches                             │
│  ├─ Participants                        │
│  ├─ Guesses                             │
│  └─ Rankings                            │
│                                         │
└─────────────────────────────────────────┘
```

## 📦 Stack Tecnológico

### Backend
- **.NET 8** - Framework moderno e performático
- **Azure Functions** - Serverless computing
- **SQL Server** - Banco de dados robusto
- **C#** - Linguagem tipada e segura

### Frontend
- **React 18** - Biblioteca UI moderna
- **TypeScript** - Segurança de tipos
- **Tailwind CSS** - Estilização utilities-first
- **Axios** - Cliente HTTP elegante

## 🚀 Quick Start

### 1. Clonar Repositório
```bash
git clone https://github.com/seu-usuario/bolao-copa-2026.git
cd bolao-copa-2026
```

### 2. Setup Backend
```bash
cd backend

# Instalar dependências
dotnet restore

# Configurar banco de dados
# Editar local.settings.json com sua connection string

# Rodar localmente
func start
```

Backend estará disponível em: `http://localhost:7071/api`

### 3. Setup Frontend
```bash
cd frontend

# Instalar dependências
npm install

# Variáveis de ambiente
echo "REACT_APP_API_URL=http://localhost:7071/api" > .env

# Iniciar servidor
npm start
```

Frontend estará disponível em: `http://localhost:3000`

### 4. Setup Banco de Dados
```bash
# Executar scripts no SQL Server Management Studio
1. database/schema.sql    (cria tabelas)
2. database/seed.sql      (carrega dados de teste)
```

## 📊 Sistema de Pontuação

| Situação | Pontos | Exemplo |
|----------|--------|---------|
| Placar exato | 3 | Acertou 1x1 quando foi 1x1 |
| Vencedor correto | 1 | Acertou que México vence (2x0) quando foi 1x0 |
| Resultado errado | 0 | Acertou 1x1 quando foi 2x1 |

### Exemplos Práticos

**Jogo Real: México 1x0 Coreia do Sul**

- Palpite: 1x0 → **3 pontos** ✅ (placar exato)
- Palpite: 2x0 → **1 ponto** ✅ (acertou que México vence)
- Palpite: 0x1 → **0 pontos** ❌ (errou o resultado)

## 🌐 Deploy no Azure

Veja [DEPLOYMENT_AZURE.md](docs/DEPLOYMENT_AZURE.md) para instruções completas de deployment.

### Resumo Rápido
```bash
# 1. Login no Azure
az login

# 2. Criar recursos
az group create --name bolao-copa-2026 --location eastus

# 3. Deploy backend
cd backend && func azure functionapp publish bolao-copa-2026-api

# 4. Deploy frontend
cd frontend && npm run build
# (deploy manual ou via Azure Static Web Apps)
```

## 📁 Estrutura do Projeto

```
bolao-copa-2026/
├── backend/                 # Azure Functions (.NET)
│   ├── Models.cs           # Modelos de dados
│   ├── Services.cs         # Lógica de negócio
│   ├── Functions.cs        # Azure Functions endpoints
│   ├── BolaoCopa.Functions.csproj
│   ├── local.settings.json # Config local
│   └── host.json          # Config Azure Functions
│
├── frontend/               # React + TypeScript
│   ├── src/
│   │   └── App.tsx        # Componente principal
│   ├── public/
│   │   └── index.html
│   ├── package.json
│   └── tailwind.config.js
│
├── database/              # Scripts SQL
│   ├── schema.sql         # Estrutura do banco
│   └── seed.sql           # Dados de teste
│
├── docs/                  # Documentação
│   ├── README.md
│   └── DEPLOYMENT_AZURE.md
│
└── .gitignore
```

## 🔧 Configuração

### Variáveis de Ambiente

**Backend (local.settings.json)**
```json
{
  "SqlConnectionString": "Server=tcp:seu-servidor.database.windows.net;Initial Catalog=BolaoCopa2026;User ID=usuario;Password=senha;",
  "AllowedOrigins": "http://localhost:3000,https://seu-dominio.com"
}
```

**Frontend (.env)**
```
REACT_APP_API_URL=http://localhost:7071/api
```

## 🎨 Funcionalidades

### ✅ Implementadas
- [x] Interface responsiva (mobile-friendly)
- [x] Listagem de jogos por rodada
- [x] Formulário de palpites
- [x] Cálculo automático de pontos
- [x] Ranking em tempo real
- [x] Histórico de palpites
- [x] Validação de dados

### 🔄 Planejadas
- [ ] Autenticação de usuários
- [ ] Sistema de convites
- [ ] Notificações em tempo real
- [ ] Chat entre participantes
- [ ] Estatísticas avançadas
- [ ] App mobile nativo
- [ ] Exportar resultados (PDF/Excel)

## 📊 Dados de Teste

O projeto vem com dados pré-carregados:

**Participantes:** 9 usuários
- Adriel Madureira (2 pts)
- Daniel Silva (4 pts) 🥇
- Emilly Santos (2 pts)
- Matheus Caetano (3 pts)
- Matheus Gazzani (4 pts) 🥈
- Amanda Oliveira (1 pt)
- Rodrigo Lemos (3 pts)
- Jesse Dias (1 pt)
- Rafael Rocha (2 pts)

**Rodada 2:** 4 jogos com resultados finais
- Tchéquia 1x1 África do Sul
- Suíça 4x1 Bósnia
- Canadá 6x0 Catar
- México 1x0 Coreia do Sul

## 📈 Monitoramento

A aplicação integra com:
- **Application Insights** - Telemetria e logs
- **Azure Monitor** - Métricas de performance
- **SQL Analytics** - Performance do banco

## 🐛 Troubleshooting

### Erro de Conexão ao Banco
```bash
# Verificar connection string
# Verificar firewall SQL Server
# Verificar credenciais
```

### Frontend não conecta ao Backend
```bash
# Verificar CORS settings
# Verificar URL da API
# Verificar se Backend está rodando
```

Veja [FAQ](docs/FAQ.md) para mais dúvidas.

## 💡 Exemplos de Uso

### Registrar um Palpite
```typescript
const guess = {
  participantId: "uuid-do-participante",
  matchId: "uuid-do-jogo",
  homeTeamScore: 2,
  awayTeamScore: 1
};

await axios.post('/api/guesses', guess);
```

### Obter Ranking
```typescript
const ranking = await axios.get('/api/tournaments/{tournamentId}/ranking');
console.log(ranking.data);
// [
//   { position: 1, name: "Daniel Silva", totalPoints: 4 },
//   ...
// ]
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a MIT License - veja [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

- 📧 Email: seu-email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/seu-usuario/bolao-copa-2026/issues)
- 💬 Discussões: [GitHub Discussions](https://github.com/seu-usuario/bolao-copa-2026/discussions)

## 🙏 Agradecimentos

- Microsoft Azure por infraestrutura confiável
- React e comunidade open-source
- Todos os testadores e contribuidores

---

<div align="center">

**Desenvolvido com ❤️ para os fãs de futebol**

⭐ Se gostou do projeto, considere deixar uma star! ⭐

</div>
