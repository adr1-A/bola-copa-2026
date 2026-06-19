# ✅ Checklist de Preparação - Bolão Copa 2026

## 📋 Antes de Começar

### 1. Instalar Ferramentas Necessárias

- [ ] **Azure CLI**
  - Link: https://aka.ms/installazurecliwindows
  - Verificar: Abrir PowerShell e digitar `az --version`

- [ ] **Azure Functions Core Tools v4**
  - Link: https://github.com/Azure/azure-functions-core-tools/releases
  - Verificar: `func --version`

- [ ] **.NET 8 SDK**
  - Link: https://dotnet.microsoft.com/en-us/download
  - Verificar: `dotnet --version`

- [ ] **Node.js (v18+)**
  - Link: https://nodejs.org/
  - Verificar: `node --version`

- [ ] **Git** (opcional mas recomendado)
  - Link: https://git-scm.com/
  - Verificar: `git --version`

### 2. Criar Conta Azure

- [ ] Ir para: https://azure.microsoft.com/free/
- [ ] Criar conta (ou usar existente)
- [ ] Ativar free trial (crédito de $200/mês por 12 meses)
- [ ] Confirmar e-mail

### 3. Preparar Credenciais

- [ ] Ter seu **e-mail Microsoft** em mãos
- [ ] Ter sua **senha** pronta
- [ ] Opcional: Configurar **autenticação de dois fatores**

---

## 🚀 Deployment Automático

### Opção 1: DEPLOY TOTAL (Recomendado)

```powershell
# Abra PowerShell como Administrator
cd C:\Users\c161847\Desktop\BolaoCopa2026
powershell -ExecutionPolicy Bypass -File deploy.ps1 -All
```

Este comando faz TUDO automaticamente:
1. ✅ Cria Resource Group
2. ✅ Cria Storage Account
3. ✅ Cria SQL Server + Database
4. ✅ Cria Function App (.NET)
5. ✅ Faz deploy do backend
6. ✅ Constrói frontend (React)
7. ✅ Salva Connection String

### Opção 2: DEPLOY EM PASSOS

Se preferir fazer passo a passo:

```powershell
# Passo 1: Login no Azure
az login

# Passo 2: Criar recursos
powershell -ExecutionPolicy Bypass -File deploy.ps1 -SetupResources

# Passo 3: Criar banco de dados (via Azure Portal)
# - Abra https://portal.azure.com
# - Procure por "SQL databases"
# - Encontre "BolaoCopa2026"
# - Clique em "Query editor"
# - Execute: database/schema.sql
# - Execute: database/seed.sql

# Passo 4: Deploy backend
powershell -ExecutionPolicy Bypass -File deploy.ps1 -DeployBackend

# Passo 5: Deploy frontend
powershell -ExecutionPolicy Bypass -File deploy.ps1 -DeployFrontend
```

---

## 📊 Depois do Deploy

### 1. Criar Banco de Dados

**Via Azure Portal (recomendado):**

1. Abra: https://portal.azure.com
2. Procure: "SQL Databases"
3. Clique: "BolaoCopa2026"
4. Clique: "Query editor" (abaixo, no menu esquerdo)
5. Faça login com as credenciais que você criou
6. Copie e cole o conteúdo de: `database/schema.sql`
7. Clique: "Run query"
8. Repita passos 6-7 com: `database/seed.sql`

**Via Azure Data Studio (alternativa):**

1. Baixe: https://aka.ms/azuredatastudio
2. Conecte ao seu servidor SQL
3. Execute os scripts em ordem: schema.sql, depois seed.sql

### 2. Configurar Frontend

**Opção A: Static Web Apps (FÁCIL - Recomendado)**

1. Abra: https://portal.azure.com
2. Procure: "Static Web Apps"
3. Clique: "+ Create"
4. Preencha:
   - **Subscription**: Sua subscription
   - **Resource Group**: bolao-copa-2026
   - **Name**: bolao-copa-frontend
   - **Hosting Plan**: Free
   - **Region**: East US
5. Clique: "Review + create" → "Create"
6. Depois, faça upload da pasta `frontend/build`

**Opção B: GitHub Actions (GRATIS para repos públicos)**

1. Faça push do projeto para GitHub
2. No GitHub, vá para: Settings → Actions → General
3. Autorize: GitHub Actions
4. Azure criará workflow automaticamente

**Opção C: Manualmente (SEM auto-deploy)**

1. A pasta `frontend/build` já está pronta
2. Comprima como `.zip`
3. Faça upload manualmente no Portal Azure

### 3. Testar a Aplicação

```powershell
# Testar Backend (substituir URL pela sua)
$apiUrl = "https://bolao-copa-api.azurewebsites.net/api"

# Listar fases
Invoke-RestMethod -Uri "$apiUrl/GetPhaseMatches?phaseId=1" -Method GET

# Listar ranking
Invoke-RestMethod -Uri "$apiUrl/GetRanking?phaseId=1" -Method GET

# Acessar Frontend
# Abra no navegador a URL da Static Web App
```

---

## ⚠️ Troubleshooting

### Erro: "Az command not found"
```powershell
# Reinstale Azure CLI
# https://aka.ms/installazurecliwindows
```

### Erro: "func command not found"
```powershell
# Reinstale Azure Functions Core Tools
# https://github.com/Azure/azure-functions-core-tools/releases
```

### Erro: "dotnet command not found"
```powershell
# Instale .NET 8 SDK
# https://dotnet.microsoft.com/download
```

### Erro: "Erro de conexão ao banco"
```powershell
# Verifique se o SQL Database foi criado
az sql db show --resource-group bolao-copa-2026 --server bolao-copa-sql --name BolaoCopa2026

# Verifique se os scripts foram executados
# (schema.sql e seed.sql no Query Editor)
```

### Erro: "CORS Error" no frontend
```powershell
# O backend precisa permitir requisições do frontend
# Será configurado automaticamente, mas se não funcionar:

az functionapp config appsettings set `
    --name bolao-copa-api `
    --resource-group bolao-copa-2026 `
    --settings AllowedOrigins="https://seu-dominio.com"
```

### Erro: "Timeout na consulta ao banco"
```
Aumentar o timeout no arquivo backend/Services.cs:
sqlConnection.ConnectionTimeout = 60; // aumentar para 60 segundos
```

---

## 💰 Estimativa de Custos

| Recurso | Gratuito | Pago |
|---------|----------|------|
| Function App | Sim (até 1M chamadas/mês) | $0.50/1M chamadas |
| SQL Database | Sim (1 semana trial) | $5-10/mês |
| Static Web Apps | Sim | - |
| Storage | Gratuito | $0.02-0.03/GB |
| **TOTAL** | **~$0** | **~$5-10/mês** |

---

## 🎯 Checklist Final

Antes de considerar o deploy completo:

- [ ] Todos os recursos foram criados no Azure Portal
- [ ] O banco de dados foi criado (schema.sql + seed.sql executados)
- [ ] O backend foi deployado (viu a mensagem de sucesso)
- [ ] O frontend foi buildado (pasta `build` foi criada)
- [ ] Testou a API com Invoke-RestMethod
- [ ] Acessou o frontend no navegador
- [ ] Consegue ver os jogos da Rodada 2
- [ ] Consegue ver o ranking com os 9 participantes
- [ ] Pode digitar um palpite e submeter

---

## 📞 Suporte

Se tiver dúvidas:

1. Verifique os logs no Azure Portal
2. Execute com `-Verbose` para mais detalhes
3. Consulte a documentação em `docs/`
4. Cheque o arquivo `CONNECTION_STRING.txt` (criado automaticamente)

---

**Status**: ✅ Pronto para deploy!

Data: $(Get-Date -Format "dd/MM/yyyy HH:mm")
