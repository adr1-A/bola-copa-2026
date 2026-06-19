# 🚀 GUIA PRÁTICO: Deploy no Azure - Bolão Copa 2026

## ✅ Pré-requisitos

Antes de começar, instale:

1. **Azure CLI** 
   - Windows: https://aka.ms/installazurecliwindows
   - Ou com PowerShell:
   ```powershell
   choco install azure-cli
   ```

2. **Azure Functions Core Tools**
   ```powershell
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```

3. **Verify Install**
   ```powershell
   az --version
   func --version
   ```

---

## 📋 PASSO 1: Login no Azure

```powershell
# Fazer login
az login

# Você será redirecionado para o navegador
# Faça login com sua conta Microsoft/Azure
```

Saiba se foi bem-sucedido quando aparecer sua conta no terminal.

---

## 📦 PASSO 2: Criar Recursos na Azure

Abra PowerShell e execute os comandos abaixo:

```powershell
# Define variáveis (customize conforme necessário)
$resourceGroup = "bolao-copa-2026"
$location = "eastus"
$functionAppName = "bolao-copa-api"
$storageAccountName = "bolaocopa2026"
$sqlServerName = "bolao-copa-sql"
$sqlDatabaseName = "BolaoCopa2026"
$sqlAdminUser = "bolaoadmin"
$sqlAdminPassword = "CopaD0Mundo2026!" # CHANGE THIS!

# ============================================================
# 1. CRIAR RESOURCE GROUP
# ============================================================

Write-Host "🔨 Criando Resource Group..." -ForegroundColor Cyan

az group create `
  --name $resourceGroup `
  --location $location

Write-Host "✅ Resource Group criado!" -ForegroundColor Green


# ============================================================
# 2. CRIAR STORAGE ACCOUNT (para Azure Functions)
# ============================================================

Write-Host "🔨 Criando Storage Account..." -ForegroundColor Cyan

az storage account create `
  --resource-group $resourceGroup `
  --name $storageAccountName `
  --location $location `
  --sku Standard_LRS

Write-Host "✅ Storage Account criado!" -ForegroundColor Green


# ============================================================
# 3. CRIAR SQL SERVER
# ============================================================

Write-Host "🔨 Criando SQL Server..." -ForegroundColor Cyan

az sql server create `
  --resource-group $resourceGroup `
  --name $sqlServerName `
  --location $location `
  --admin-user $sqlAdminUser `
  --admin-password $sqlAdminPassword

Write-Host "✅ SQL Server criado!" -ForegroundColor Green


# ============================================================
# 4. CRIAR SQL DATABASE
# ============================================================

Write-Host "🔨 Criando SQL Database..." -ForegroundColor Cyan

az sql db create `
  --resource-group $resourceGroup `
  --server $sqlServerName `
  --name $sqlDatabaseName `
  --edition Basic

Write-Host "✅ SQL Database criado!" -ForegroundColor Green


# ============================================================
# 5. CONFIGURAR FIREWALL (IMPORTANTE!)
# ============================================================

Write-Host "🔨 Configurando Firewall..." -ForegroundColor Cyan

# Permitir conexões do Azure
az sql server firewall-rule create `
  --resource-group $resourceGroup `
  --server $sqlServerName `
  --name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0

Write-Host "✅ Firewall configurado!" -ForegroundColor Green


# ============================================================
# 6. CRIAR FUNCTION APP
# ============================================================

Write-Host "🔨 Criando Function App..." -ForegroundColor Cyan

az functionapp create `
  --resource-group $resourceGroup `
  --consumption-plan-location $location `
  --runtime dotnet-isolated `
  --runtime-version 8.0 `
  --functions-version 4 `
  --name $functionAppName `
  --storage-account $storageAccountName

Write-Host "✅ Function App criado!" -ForegroundColor Green


# ============================================================
# 7. GERAR CONNECTION STRING
# ============================================================

Write-Host "📋 Gerando Connection String..." -ForegroundColor Yellow

$connectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlAdminUser;Password=$sqlAdminPassword;Encrypt=True;Connection Timeout=30;"

Write-Host ""
Write-Host "🔑 SALVE ESTA CONNECTION STRING:" -ForegroundColor Yellow
Write-Host $connectionString -ForegroundColor Green
Write-Host ""


# ============================================================
# 8. RESUMO DOS RECURSOS CRIADOS
# ============================================================

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         RECURSOS CRIADOS COM SUCESSO! ✅                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 Resource Group: $resourceGroup" -ForegroundColor Green
Write-Host "💾 Storage Account: $storageAccountName" -ForegroundColor Green
Write-Host "📡 Function App: $functionAppName" -ForegroundColor Green
Write-Host "🗄️  SQL Server: $sqlServerName" -ForegroundColor Green
Write-Host "🗄️  SQL Database: $sqlDatabaseName" -ForegroundColor Green
Write-Host ""
```

---

## 🗄️ PASSO 3: Criar Tabelas no Banco de Dados

**Opção A: Via Azure Portal (Mais Fácil)**

1. Vá para https://portal.azure.com
2. Procure por "SQL databases"
3. Clique em seu banco (BolaoCopa2026)
4. Clique em "Query editor"
5. Cole o conteúdo de `database/schema.sql`
6. Execute
7. Cole o conteúdo de `database/seed.sql`
8. Execute

**Opção B: Via Azure Data Studio (Recomendado)**

1. Instale: https://learn.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio
2. Conecte ao servidor SQL
3. Abra `database/schema.sql` e execute
4. Abra `database/seed.sql` e execute

---

## 🎯 PASSO 4: Deploy do Backend (Azure Functions)

```powershell
# Navegue até a pasta do backend
cd C:\Users\c161847\Desktop\BolaoCopa2026\backend

# ============================================================
# 1. BUILD DO PROJETO
# ============================================================

Write-Host "🔨 Building projeto .NET..." -ForegroundColor Cyan

dotnet publish -c Release -o bin/Release/publish

Write-Host "✅ Build concluído!" -ForegroundColor Green


# ============================================================
# 2. CONFIGURAR APP SETTINGS NO AZURE
# ============================================================

Write-Host "⚙️  Configurando App Settings..." -ForegroundColor Yellow

$functionAppName = "bolao-copa-api"
$resourceGroup = "bolao-copa-2026"
$connectionString = "Server=tcp:bolao-copa-sql.database.windows.net,1433;Initial Catalog=BolaoCopa2026;Persist Security Info=False;User ID=bolaoadmin;Password=CopaD0Mundo2026!;Encrypt=True;Connection Timeout=30;"

az functionapp config appsettings set `
  --name $functionAppName `
  --resource-group $resourceGroup `
  --settings `
    SqlConnectionString="$connectionString" `
    AllowedOrigins="https://seu-dominio.com"

Write-Host "✅ App Settings configurados!" -ForegroundColor Green


# ============================================================
# 3. FAZER DEPLOY
# ============================================================

Write-Host "🚀 Fazendo deploy..." -ForegroundColor Cyan

func azure functionapp publish $functionAppName --build remote

Write-Host "✅ Backend deployed com sucesso!" -ForegroundColor Green
Write-Host "🔗 URL: https://$functionAppName.azurewebsites.net/api" -ForegroundColor Yellow
```

---

## 🎨 PASSO 5: Deploy do Frontend (Static Web App)

```powershell
# Navegue até a pasta do frontend
cd C:\Users\c161847\Desktop\BolaoCopa2026\frontend

# ============================================================
# 1. INSTALAR DEPENDÊNCIAS
# ============================================================

npm install

# ============================================================
# 2. CONFIGURAR VARIÁVEIS DE AMBIENTE
# ============================================================

# Crie arquivo .env.production
@"
REACT_APP_API_URL=https://bolao-copa-api.azurewebsites.net/api
"@ | Out-File -FilePath ".env.production" -Encoding UTF8

Write-Host "✅ Variáveis configuradas!" -ForegroundColor Green

# ============================================================
# 3. BUILD
# ============================================================

Write-Host "🔨 Building React..." -ForegroundColor Cyan

npm run build

Write-Host "✅ Build concluído!" -ForegroundColor Green


# ============================================================
# 4. DEPLOY (VIA AZURE PORTAL)
# ============================================================

Write-Host ""
Write-Host "📋 Para fazer deploy do Frontend:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Vá para: https://portal.azure.com" -ForegroundColor White
Write-Host "2. Procure: 'Static Web Apps'" -ForegroundColor White
Write-Host "3. Clique: '+Create'" -ForegroundColor White
Write-Host "4. Configure:" -ForegroundColor White
Write-Host "   - Subscription: Sua subscription" -ForegroundColor Gray
Write-Host "   - Resource Group: bolao-copa-2026" -ForegroundColor Gray
Write-Host "   - Name: bolao-copa-web" -ForegroundColor Gray
Write-Host "   - Hosting Plan: Free" -ForegroundColor Gray
Write-Host "5. Clique: 'Create'" -ForegroundColor White
Write-Host ""
```

**Ou fazer deploy via CLI:**

```powershell
# Se tiver uma conta GitHub conectada:

az staticwebapp create `
  --name bolao-copa-web `
  --resource-group bolao-copa-2026 `
  --source "C:\Users\c161847\Desktop\BolaoCopa2026\frontend\build" `
  --location eastus

# Ou fazer upload manual da pasta 'build'
```

---

## ✅ PASSO 6: Testar Tudo

```powershell
# Testar Backend
$apiUrl = "https://bolao-copa-api.azurewebsites.net/api"

# Obter ranking
$response = Invoke-RestMethod -Uri "$apiUrl/tournaments/550e8400-e29b-41d4-a716-446655440000/ranking" -Method Get

Write-Host "🎯 Resposta do API:" -ForegroundColor Green
$response | ConvertTo-Json | Write-Host

# Deve retornar JSON com ranking dos 9 participantes
```

---

## 🔐 PASSO 7: Configurar CORS (Se necessário)

```powershell
$functionAppName = "bolao-copa-api"
$resourceGroup = "bolao-copa-2026"
$dominio = "seu-dominio.com" # CHANGE THIS

az functionapp cors add `
  --name $functionAppName `
  --resource-group $resourceGroup `
  --allowed-origins "https://$dominio" "http://localhost:3000"
```

---

## 📊 PASSO 8: Verificar Deployment

Vá para https://portal.azure.com e:

1. **Procure seu Resource Group** (bolao-copa-2026)
2. **Veja todos os recursos criados:**
   - ✅ Function App (bolao-copa-api)
   - ✅ SQL Database (BolaoCopa2026)
   - ✅ Storage Account (bolaocopa2026)
   - ✅ Static Web App (bolao-copa-web)

3. **Clique em cada um e copie a URL:**
   - Function App URL: `https://bolao-copa-api.azurewebsites.net`
   - Static Web App URL: `https://xxx.azurestaticapps.net`

---

## 🎉 PRONTO!

Sua aplicação está no ar! 🚀

**URLs Finais:**
- 🎨 Frontend: `https://seu-app.azurestaticapps.net`
- 📡 Backend: `https://bolao-copa-api.azurewebsites.net/api`
- 🗄️  Database: `bolao-copa-sql.database.windows.net`

---

## 💰 Verificar Custos

```powershell
# Ver custos estimados
az consumption budget create `
  --name "Bolao-Copa-Budget" `
  --category "Cost" `
  --amount 50 `
  --time-grain Monthly `
  --time-period (Get-Date).Year
```

**Estimativa de Custo/mês:**
- Azure Functions: $0.20 (primeiros 1M chamadas grátis)
- SQL Database (Basic): $5-10
- Static Web App: $0
- **Total: ~$5-10/mês** ✅

---

## 🐛 Troubleshooting

### Erro: "Connection timeout"
```powershell
# Verificar firewall
az sql server firewall-rule list `
  --resource-group bolao-copa-2026 `
  --server bolao-copa-sql

# Adicionar seu IP (se necessário)
$myIP = "seu-ip-aqui"

az sql server firewall-rule create `
  --resource-group bolao-copa-2026 `
  --server bolao-copa-sql `
  --name AllowMyIP `
  --start-ip-address $myIP `
  --end-ip-address $myIP
```

### Erro: "Function app not found"
```powershell
# Listar apps
az functionapp list --resource-group bolao-copa-2026
```

### Erro: "Deployment failed"
```powershell
# Ver logs
az functionapp log tail `
  --name bolao-copa-api `
  --resource-group bolao-copa-2026
```

---

## 📞 Próximos Passos

1. ✅ Faça o deploy (siga os passos acima)
2. ✅ Teste a API
3. ✅ Configure domínio customizado (opcional)
4. ✅ Adicione SSL (automático)
5. ✅ Configure backups automáticos
6. ✅ Monitore com Application Insights

---

**Parabéns! Sua aplicação está ao vivo! 🎉**
