# ============================================================================
# SCRIPT DE DEPLOY AUTOMATICO - Bolao Copa 2026 para Azure
# ============================================================================

param(
    [switch]$Help,
    [switch]$SetupResources,
    [switch]$DeployBackend,
    [switch]$DeployFrontend,
    [switch]$All
)

# ============================================================================
# FUNCOES AUXILIARES
# ============================================================================

function Show-Help {
    Write-Host @"
    
╔════════════════════════════════════════════════════════════════════════════╗
║              SCRIPT DE DEPLOY - Bolao Copa 2026 para Azure                ║
╚════════════════════════════════════════════════════════════════════════════╝

OPCOES:

    -All              Execute todos os passos (recomendado!)
    -SetupResources   Criar recursos no Azure (SQL, Functions, Storage)
    -DeployBackend    Deploy do backend (Azure Functions)
    -DeployFrontend   Deploy do frontend (build + configuracao)
    -Help             Mostrar esta mensagem

EXEMPLOS:

    # Fazer tudo (recomendado)
    powershell -ExecutionPolicy Bypass -File deploy.ps1 -All

    # Apenas criar recursos
    powershell -ExecutionPolicy Bypass -File deploy.ps1 -SetupResources

    # Apenas deploy backend
    powershell -ExecutionPolicy Bypass -File deploy.ps1 -DeployBackend

OBSERVACOES:

    - Precisa estar logado no Azure (az login)
    - Instale: Azure CLI, Functions Core Tools, .NET 8 SDK, Node.js
    - Customize as variaveis no inicio do script
    - Salve a connection string que sera gerada!

"@
}

function Test-Prerequisites {
    Write-Host "🔍 Verificando pré-requisitos..." -ForegroundColor Cyan
    
    $prerequisites = @(
        @{ Name = "Azure CLI"; Command = "az --version" }
        @{ Name = "Azure Functions"; Command = "func --version" }
        @{ Name = ".NET 8"; Command = "dotnet --version" }
        @{ Name = "Node.js"; Command = "node --version" }
    )
    
    foreach ($prereq in $prerequisites) {
        try {
            $output = & $prereq.Command 2>&1
            Write-Host "✅ $($prereq.Name) instalado" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ $($prereq.Name) NAO encontrado! Instale em:" -ForegroundColor Red
            Write-Host "   https://aka.ms/installazurecliwindows (Azure CLI)" -ForegroundColor Yellow
            exit 1
        }
    }
    
    Write-Host ""
}

function Test-AzureLogin {
    Write-Host "🔐 Verificando login Azure..." -ForegroundColor Cyan
    
    try {
        $account = az account show --query "user.name" -o tsv
        Write-Host "✅ Logado como: $account" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Nao esta logado no Azure!" -ForegroundColor Red
        Write-Host "Execute: az login" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host ""
}

function Setup-AzureResources {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              CRIANDO RECURSOS NO AZURE                                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # ========== VARIAVEIS ==========
    $resourceGroup = "bolao-copa-2026"
    $location = "eastus"
    $functionAppName = "bolao-copa-api"
    $storageAccountName = "bolaocopa2026"
    $sqlServerName = "bolao-copa-sql"
    $sqlDatabaseName = "BolaoCopa2026"
    $sqlAdminUser = "bolaoadmin"
    $sqlAdminPassword = "CopaD0Mundo2026!" # IMPORTANTE: MUDE ISSO!
    
    Write-Host "⚙️  Parametros:" -ForegroundColor Yellow
    Write-Host "   Resource Group: $resourceGroup"
    Write-Host "   Location: $location"
    Write-Host "   Function App: $functionAppName"
    Write-Host "   SQL Server: $sqlServerName"
    Write-Host ""
    
    # ========== 1. RESOURCE GROUP ==========
    Write-Host "🔨 [1/7] Criando Resource Group..." -ForegroundColor Cyan
    az group create --name $resourceGroup --location $location
    Write-Host "✅ Resource Group criado!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 2. STORAGE ACCOUNT ==========
    Write-Host "🔨 [2/7] Criando Storage Account..." -ForegroundColor Cyan
    az storage account create `
        --resource-group $resourceGroup `
        --name $storageAccountName `
        --location $location `
        --sku Standard_LRS
    Write-Host "✅ Storage Account criado!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 3. SQL SERVER ==========
    Write-Host "🔨 [3/7] Criando SQL Server..." -ForegroundColor Cyan
    az sql server create `
        --resource-group $resourceGroup `
        --name $sqlServerName `
        --location $location `
        --admin-user $sqlAdminUser `
        --admin-password $sqlAdminPassword
    Write-Host "✅ SQL Server criado!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 4. SQL DATABASE ==========
    Write-Host "🔨 [4/7] Criando SQL Database..." -ForegroundColor Cyan
    az sql db create `
        --resource-group $resourceGroup `
        --server $sqlServerName `
        --name $sqlDatabaseName `
        --edition Basic
    Write-Host "✅ SQL Database criado!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 5. FIREWALL ==========
    Write-Host "🔨 [5/7] Configurando Firewall..." -ForegroundColor Cyan
    az sql server firewall-rule create `
        --resource-group $resourceGroup `
        --server $sqlServerName `
        --name AllowAzureServices `
        --start-ip-address 0.0.0.0 `
        --end-ip-address 0.0.0.0
    Write-Host "✅ Firewall configurado!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 6. FUNCTION APP ==========
    Write-Host "🔨 [6/7] Criando Function App..." -ForegroundColor Cyan
    az functionapp create `
        --resource-group $resourceGroup `
        --consumption-plan-location $location `
        --runtime dotnet-isolated `
        --runtime-version 8.0 `
        --functions-version 4 `
        --name $functionAppName `
        --storage-account $storageAccountName
    Write-Host "✅ Function App criado!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 7. GERAR CONNECTION STRING ==========
    Write-Host "🔨 [7/7] Gerando Connection String..." -ForegroundColor Cyan
    $connectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Initial Catalog=$sqlDatabaseName;Persist Security Info=False;User ID=$sqlAdminUser;Password=$sqlAdminPassword;Encrypt=True;Connection Timeout=30;"
    Write-Host "✅ Connection String gerada!" -ForegroundColor Green
    Write-Host ""
    
    # ========== RESUMO ==========
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              RECURSOS CRIADOS COM SUCESSO! ✅                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Resource Group: $resourceGroup" -ForegroundColor Green
    Write-Host "💾 Storage Account: $storageAccountName" -ForegroundColor Green
    Write-Host "📡 Function App: $functionAppName" -ForegroundColor Green
    Write-Host "🗄️  SQL Server: $sqlServerName.database.windows.net" -ForegroundColor Green
    Write-Host "🗄️  SQL Database: $sqlDatabaseName" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔑 CONNECTION STRING (SALVE ISSO!):" -ForegroundColor Yellow
    Write-Host $connectionString -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  PROXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "1. Crie as tabelas executando database/schema.sql no banco" -ForegroundColor White
    Write-Host "2. Carregue os dados executando database/seed.sql" -ForegroundColor White
    Write-Host "3. Use: powershell -ExecutionPolicy Bypass -File deploy.ps1 -DeployBackend" -ForegroundColor White
    Write-Host ""
    
    # Salvar connection string em arquivo
    $connectionString | Out-File -FilePath "$PSScriptRoot\CONNECTION_STRING.txt" -Encoding UTF8
    Write-Host "💾 Connection String salva em: CONNECTION_STRING.txt" -ForegroundColor Green
    Write-Host ""
}

function Deploy-Backend {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              FAZENDO DEPLOY DO BACKEND                                   ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $backendPath = Join-Path $PSScriptRoot "backend"
    $functionAppName = "bolao-copa-api"
    $resourceGroup = "bolao-copa-2026"
    $connectionString = Get-Content (Join-Path $PSScriptRoot "CONNECTION_STRING.txt")
    
    # ========== 1. BUILD ==========
    Write-Host "🔨 [1/3] Building projeto .NET..." -ForegroundColor Cyan
    Push-Location $backendPath
    dotnet publish -c Release -o bin/Release/publish
    Pop-Location
    Write-Host "✅ Build concluído!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 2. CONFIGURAR APP SETTINGS ==========
    Write-Host "⚙️  [2/3] Configurando App Settings..." -ForegroundColor Cyan
    az functionapp config appsettings set `
        --name $functionAppName `
        --resource-group $resourceGroup `
        --settings `
            SqlConnectionString="$connectionString" `
            AllowedOrigins="https://seu-dominio.com"
    Write-Host "✅ App Settings configurados!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 3. FAZER DEPLOY ==========
    Write-Host "🚀 [3/3] Fazendo deploy..." -ForegroundColor Cyan
    Push-Location $backendPath
    func azure functionapp publish $functionAppName --build remote
    Pop-Location
    Write-Host "✅ Backend deployed com sucesso!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              BACKEND DEPLOYED COM SUCESSO! ✅                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🔗 URL da API: https://$functionAppName.azurewebsites.net/api" -ForegroundColor Yellow
    Write-Host ""
}

function Deploy-Frontend {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              PREPARANDO FRONTEND PARA DEPLOY                             ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $frontendPath = Join-Path $PSScriptRoot "frontend"
    
    # ========== 1. INSTALAR DEPENDENCIAS ==========
    Write-Host "🔨 [1/3] Instalando dependências..." -ForegroundColor Cyan
    Push-Location $frontendPath
    npm install
    Pop-Location
    Write-Host "✅ Dependências instaladas!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 2. CONFIGURAR VARIAVEIS ==========
    Write-Host "⚙️  [2/3] Configurando variáveis de ambiente..." -ForegroundColor Cyan
    $envContent = @"
REACT_APP_API_URL=https://bolao-copa-api.azurewebsites.net/api
"@
    $envContent | Out-File -FilePath (Join-Path $frontendPath ".env.production") -Encoding UTF8
    Write-Host "✅ Variáveis configuradas!" -ForegroundColor Green
    Write-Host ""
    
    # ========== 3. BUILD ==========
    Write-Host "🔨 [3/3] Building React..." -ForegroundColor Cyan
    Push-Location $frontendPath
    npm run build
    Pop-Location
    Write-Host "✅ Build concluído!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              FRONTEND PRONTO PARA DEPLOY! ✅                             ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📁 Arquivos de build estao em: frontend/build" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  PROXIMOS PASSOS:" -ForegroundColor Yellow
    Write-Host "1. Vá para: https://portal.azure.com" -ForegroundColor White
    Write-Host "2. Procure: 'Static Web Apps'" -ForegroundColor White
    Write-Host "3. Clique: '+Create'" -ForegroundColor White
    Write-Host "4. Configure como desejado (siga o wizard)" -ForegroundColor White
    Write-Host "5. Faça upload da pasta 'build' ou conecte seu GitHub" -ForegroundColor White
    Write-Host ""
}

function Deploy-All {
    Test-Prerequisites
    Test-AzureLogin
    Setup-AzureResources
    Deploy-Backend
    Deploy-Frontend
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           DEPLOY CONCLUIDO COM SUCESSO! 🎉                               ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# MAIN
# ============================================================================

if ($Help) {
    Show-Help
}
elseif ($All) {
    Deploy-All
}
elseif ($SetupResources) {
    Test-Prerequisites
    Test-AzureLogin
    Setup-AzureResources
}
elseif ($DeployBackend) {
    Test-Prerequisites
    Test-AzureLogin
    Deploy-Backend
}
elseif ($DeployFrontend) {
    Test-Prerequisites
    Deploy-Frontend
}
else {
    Show-Help
}
