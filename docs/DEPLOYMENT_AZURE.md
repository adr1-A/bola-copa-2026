# Bolão Copa 2026 - Guia de Deploy no Azure

## 🌐 Arquitetura da Solução

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Cloud                            │
├─────────────────────────────────────────────────────────────┤
│  Frontend                  Backend           Database        │
│  ┌──────────────┐      ┌──────────────┐   ┌──────────────┐  │
│  │Static Web    │      │Azure         │   │Azure SQL     │  │
│  │App (React)   │◄────►│Functions     │◄─►│Database      │  │
│  │CDN Global    │      │(.NET 8)      │   │(SQL Server)  │  │
│  └──────────────┘      └──────────────┘   └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Pré-requisitos

- Conta Azure ativa
- Azure CLI instalado
- .NET 8 SDK
- Node.js 18+
- Git (opcional)

## 🚀 Passo a Passo

### 1. Preparar Ambiente Azure

```bash
# Login no Azure
az login

# Criar resource group
az group create \
  --name bolao-copa-2026 \
  --location eastus

# Variáveis de ambiente
$resourceGroup = "bolao-copa-2026"
$location = "eastus"
$functionAppName = "bolao-copa-2026-api"
$storageAccountName = "bolaocopa2026"
$sqlServerName = "bolao-copa-2026-sql"
$sqlDatabaseName = "BolaoCopa2026"
$staticWebAppName = "bolao-copa-2026-web"
```

### 2. Criar Storage Account (para Azure Functions)

```bash
az storage account create \
  --resource-group $resourceGroup \
  --name $storageAccountName \
  --location $location \
  --sku Standard_LRS
```

### 3. Criar Function App

```bash
az functionapp create \
  --resource-group $resourceGroup \
  --consumption-plan-location $location \
  --runtime dotnet-isolated \
  --runtime-version 8.0 \
  --functions-version 4 \
  --name $functionAppName \
  --storage-account $storageAccountName
```

### 4. Criar SQL Server e Database

```bash
# Criar SQL Server
az sql server create \
  --resource-group $resourceGroup \
  --name $sqlServerName \
  --location $location \
  --admin-user bolaouser \
  --admin-password 'YourP@ssw0rd123'

# Criar Database
az sql db create \
  --resource-group $resourceGroup \
  --server $sqlServerName \
  --name $sqlDatabaseName \
  --edition Basic

# Configurar firewall para Azure
az sql server firewall-rule create \
  --resource-group $resourceGroup \
  --server $sqlServerName \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Configurar firewall para seu IP (opcional)
# az sql server firewall-rule create \
#   --resource-group $resourceGroup \
#   --server $sqlServerName \
#   --name AllowMyIP \
#   --start-ip-address YOUR.IP.ADDRESS \
#   --end-ip-address YOUR.IP.ADDRESS
```

### 5. Executar Scripts SQL

```bash
# Connection String
$connectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=bolaouser;Password=YourP@ssw0rd123;Encrypt=True;Connection Timeout=30;"

# Usar Azure Data Studio ou Azure Portal para executar:
# 1. database/schema.sql
# 2. database/seed.sql
```

### 6. Deploy do Backend (Azure Functions)

```bash
cd backend

# Build
dotnet publish -c Release -o bin/Release/publish

# Update local.settings.json com connection string
# Depois fazer deploy
func azure functionapp publish $functionAppName

# Verificar deployment
az functionapp list --resource-group $resourceGroup
```

### 7. Configurar App Settings

```bash
# Adicionar connection string no Function App
az functionapp config appsettings set \
  --name $functionAppName \
  --resource-group $resourceGroup \
  --settings \
  SqlConnectionString="$connectionString" \
  AllowedOrigins="https://seu-dominio.com"
```

### 8. Deploy do Frontend (Static Web App)

```bash
cd frontend

# Build
npm run build

# Deploy com Static Web App (requer extensão)
az staticwebapp create \
  --name $staticWebAppName \
  --resource-group $resourceGroup \
  --source ./build \
  --location eastus \
  --build-folder build

# Ou usar Azure Portal para conectar com GitHub
```

### 9. Configurar CORS no Backend

```bash
# Adicionar origem permitida
az functionapp cors add \
  --name $functionAppName \
  --resource-group $resourceGroup \
  --allowed-origins "https://seu-dominio.com" "http://localhost:3000"
```

### 10. Verificar Deployment

```bash
# Testar API
$functionUrl = "https://$functionAppName.azurewebsites.net/api/tournaments/550e8400-e29b-41d4-a716-446655440000/ranking"

curl -X GET $functionUrl

# Deve retornar JSON com ranking dos participantes
```

## 🔐 Segurança

### Recomendações

1. **Key Vault** para senhas
   ```bash
   az keyvault create \
     --resource-group $resourceGroup \
     --name bolao-copa-2026-kv
   ```

2. **Application Insights** para monitoramento
   ```bash
   az monitor app-insights component create \
     --app bolao-copa-2026-insights \
     --location $location \
     --resource-group $resourceGroup
   ```

3. **Managed Identity** para Function App
   ```bash
   az functionapp identity assign \
     --resource-group $resourceGroup \
     --name $functionAppName
   ```

## 📊 Monitoramento

```bash
# Ver logs
az functionapp log tail \
  --name $functionAppName \
  --resource-group $resourceGroup

# Métricas
az monitor metrics list \
  --resource /subscriptions/{subscription-id}/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$functionAppName
```

## 💰 Estimativa de Custos

| Serviço | Plano | Custo Mensal (aprox) |
|---------|-------|--------|
| Azure Functions | Consumption | $0.20 (primeiras 1M requisições grátis) |
| SQL Database | Basic | $5-10 |
| Static Web App | Free | $0 |
| **Total** | | **$5-10/mês** |

## 🔄 CI/CD (GitHub Actions)

Crie `.github/workflows/deploy.yml`:

```yaml
name: Deploy Bolão Copa 2026

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      
      - name: Build Backend
        run: dotnet publish backend -c Release -o backend/publish
      
      - name: Deploy Backend
        uses: Azure/functions-action@v1
        with:
          app-name: ${{ env.FUNCTION_APP_NAME }}
          package: 'backend/publish'
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Build Frontend
        run: |
          cd frontend
          npm install
          npm run build
      
      - name: Deploy Frontend
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "frontend/build"
```

## 📱 Domínio Personalizado

```bash
# Adicionar domínio customizado
az appservice web config hostname add \
  --webapp-name $functionAppName \
  --resource-group $resourceGroup \
  --hostname seu-dominio.com

# Configurar SSL
az appservice web config ssl bind \
  --resource-group $resourceGroup \
  --name $functionAppName \
  --certificate-name seu-certificado
```

## ⚠️ Troubleshooting

### Erro de conexão ao banco
```bash
# Verificar firewall
az sql server firewall-rule list \
  --resource-group $resourceGroup \
  --server $sqlServerName

# Limpar cache
az functionapp config appsettings delete \
  --name $functionAppName \
  --resource-group $resourceGroup \
  --setting-names SqlConnectionString
```

### Function App não inicia
```bash
# Ver logs
az functionapp log tail \
  --name $functionAppName \
  --resource-group $resourceGroup

# Reiniciar
az functionapp restart \
  --name $functionAppName \
  --resource-group $resourceGroup
```

## 📞 Suporte

Para problemas:
1. Verificar **Activity Log** no Azure Portal
2. Consultar **Application Insights**
3. Verificar **Function App Logs**

---

**Deploy Concluído! 🎉**
Sua aplicação está rodando em:
- Frontend: `https://$staticWebAppName.azurewebsites.net`
- Backend: `https://$functionAppName.azurewebsites.net/api`
