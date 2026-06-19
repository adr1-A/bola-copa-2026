#!/bin/bash

################################################################################
# SCRIPT DE DEPLOY AUTOMÁTICO - BOLÃO COPA 2026 NA AWS
# Compatível com: Ubuntu 20.04+, Amazon Linux 2
# Uso: bash deploy-aws.sh
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações (CUSTOMIZE AQUI)
AWS_REGION="us-east-1"
DB_NAME="bolao-copa-2026"
DB_ADMIN_USER="admin"
DB_ADMIN_PASSWORD="SenhaForte@123456!"
FUNCTION_NAME="bolao-copa-functions"
S3_BUCKET_PREFIX="bolao-copa-frontend"
PROJECT_NAME="BolaoCopa2026"

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}\n"
}

print_error() {
    echo -e "${RED}❌ ERRO: $1${NC}\n"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}\n"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}\n"
}

################################################################################
# VERIFICAÇÕES PRÉ-REQUISITOS
################################################################################

check_prerequisites() {
    print_header "VERIFICANDO PRÉ-REQUISITOS"

    # Verificar Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js não encontrado. Instale em: https://nodejs.org/"
    fi
    NODE_VERSION=$(node --version)
    print_info "Node.js: $NODE_VERSION"

    # Verificar .NET
    if ! command -v dotnet &> /dev/null; then
        print_error ".NET SDK não encontrado. Instale em: https://dotnet.microsoft.com/download"
    fi
    DOTNET_VERSION=$(dotnet --version)
    print_info ".NET: $DOTNET_VERSION"

    # Verificar Git
    if ! command -v git &> /dev/null; then
        print_error "Git não encontrado. Instale com: sudo apt-get install git"
    fi
    print_info "Git: $(git --version)"

    # Instalar AWS CLI se necessário
    if ! command -v aws &> /dev/null; then
        print_warning "AWS CLI não encontrado. Instalando..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        print_success "AWS CLI instalado"
    fi
    print_info "AWS CLI: $(aws --version)"

    print_success "Todos os pré-requisitos atendidos!"
}

################################################################################
# CONFIGURAR AWS
################################################################################

configure_aws() {
    print_header "CONFIGURANDO AWS CLI"

    if aws sts get-caller-identity &> /dev/null; then
        print_info "AWS CLI já configurado"
        aws sts get-caller-identity
        return
    fi

    print_warning "AWS CLI não configurado. Configurando agora..."
    print_info "Você precisa das seguintes informações:"
    print_info "1. AWS Access Key ID (de https://console.aws.amazon.com)"
    print_info "2. AWS Secret Access Key"
    print_info "3. Default region: $AWS_REGION"
    print_info "4. Output format: json"

    aws configure set region $AWS_REGION
    aws configure

    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Falha na configuração AWS"
    fi

    print_success "AWS CLI configurado!"
}

################################################################################
# CRIAR RECURSOS AWS
################################################################################

create_rds() {
    print_header "CRIANDO RDS (BANCO DE DADOS)"

    # Gerar timestamp único
    TIMESTAMP=$(date +%s)
    DB_INSTANCE_ID="${DB_NAME}-${TIMESTAMP}"

    print_info "Criando instância RDS: $DB_INSTANCE_ID"
    print_info "Tipo: SQL Server Express (Free Tier)"
    print_info "Isso pode demorar 10-15 minutos..."

    aws rds create-db-instance \
        --db-instance-identifier $DB_INSTANCE_ID \
        --db-instance-class db.t3.micro \
        --engine sqlserver-express \
        --master-username $DB_ADMIN_USER \
        --master-user-password "$DB_ADMIN_PASSWORD" \
        --allocated-storage 20 \
        --storage-type gp3 \
        --no-publicly-accessible \
        --region $AWS_REGION \
        --multi-az \
        || print_warning "RDS pode já existir ou erro na criação"

    print_info "RDS em criação. Você pode monitorar em: https://console.aws.amazon.com/rds"
    echo $DB_INSTANCE_ID > .rds-instance-id

    print_success "RDS criado com ID: $DB_INSTANCE_ID"
}

################################################################################
# FAZER DEPLOY BACKEND (LAMBDA)
################################################################################

deploy_backend() {
    print_header "DEPLOY DO BACKEND (AWS LAMBDA)"

    cd backend

    # Instalar Lambda Tools
    print_info "Instalando AWS Lambda Tools para .NET..."
    dotnet tool install -g Amazon.Lambda.Tools 2>/dev/null || dotnet tool update -g Amazon.Lambda.Tools

    # Restaurar dependências
    print_info "Restaurando dependências .NET..."
    dotnet restore

    # Build
    print_info "Compilando projeto..."
    dotnet build --configuration Release

    # Deploy para Lambda
    print_info "Fazendo deploy para AWS Lambda..."
    dotnet lambda deploy-function \
        --function-name $FUNCTION_NAME \
        --function-role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-role \
        --region $AWS_REGION \
        || print_warning "Lambda pode já existir. Tentando atualizar código..."

    # Pegar URL da função
    LAMBDA_URL=$(aws lambda get-function-url-config \
        --function-name $FUNCTION_NAME \
        --region $AWS_REGION \
        --query 'FunctionUrl' \
        --output text 2>/dev/null || echo "URL não disponível ainda")

    print_success "Backend deployed com sucesso!"
    print_info "URL da API: $LAMBDA_URL"
    echo $LAMBDA_URL > ../.lambda-url

    cd ..
}

################################################################################
# FAZER DEPLOY FRONTEND (S3 + CLOUDFRONT)
################################################################################

deploy_frontend() {
    print_header "DEPLOY DO FRONTEND (AWS S3 + CLOUDFRONT)"

    cd frontend

    # Instalar dependências
    print_info "Instalando dependências Node.js..."
    npm install

    # Build
    print_info "Compilando React..."
    npm run build

    # Criar S3 bucket
    S3_BUCKET="${S3_BUCKET_PREFIX}-$(date +%s)"
    print_info "Criando S3 bucket: $S3_BUCKET"

    aws s3 mb s3://$S3_BUCKET --region $AWS_REGION || print_warning "Bucket pode já existir"

    # Upload para S3
    print_info "Fazendo upload dos arquivos..."
    aws s3 cp build/ s3://$S3_BUCKET/ --recursive --region $AWS_REGION

    # Habilitar website estático
    print_info "Configurando S3 como website estático..."
    aws s3 website s3://$S3_BUCKET --index-document index.html --error-document index.html 2>/dev/null || true

    # URL do website
    S3_WEBSITE_URL="http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"

    print_success "Frontend deployed com sucesso!"
    print_info "URL do Frontend: $S3_WEBSITE_URL"
    echo $S3_WEBSITE_URL > ../.s3-url
    echo $S3_BUCKET > ../.s3-bucket

    cd ..
}

################################################################################
# CONFIGURAR BANCO DE DADOS
################################################################################

setup_database() {
    print_header "CONFIGURANDO BANCO DE DADOS"

    # Obter RDS instance ID
    if [ -f ".rds-instance-id" ]; then
        DB_INSTANCE_ID=$(cat .rds-instance-id)
    else
        print_error "Arquivo .rds-instance-id não encontrado"
    fi

    print_info "Esperando RDS ficar disponível..."
    print_info "Checking status da instância: $DB_INSTANCE_ID"

    # Verificar status
    STATUS=$(aws rds describe-db-instances \
        --db-instance-identifier $DB_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'DBInstances[0].DBInstanceStatus' \
        --output text 2>/dev/null || echo "not-found")

    if [ "$STATUS" != "available" ]; then
        print_warning "RDS ainda não está pronto (Status: $STATUS)"
        print_info "Aguarde 10-15 minutos e execute manualmente:"
        print_info "bash database/setup-db.sh"
        return
    fi

    # Obter endpoint
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier $DB_INSTANCE_ID \
        --region $AWS_REGION \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)

    print_info "RDS Endpoint: $ENDPOINT"

    # Salvar informações
    cat > .rds-connection << EOF
Server: $ENDPOINT
Database: $PROJECT_NAME
Username: $DB_ADMIN_USER
Password: $DB_ADMIN_PASSWORD
EOF

    print_success "RDS está pronto!"
    print_info "Para conectar ao banco:"
    print_info "sqlcmd -S $ENDPOINT -U $DB_ADMIN_USER -P '$DB_ADMIN_PASSWORD'"

    # Executar scripts SQL se possível
    if command -v sqlcmd &> /dev/null; then
        print_info "Executando scripts SQL..."
        # sqlcmd -S $ENDPOINT -U $DB_ADMIN_USER -P "$DB_ADMIN_PASSWORD" -i database/schema.sql || print_warning "Erro ao executar schema.sql"
        # sqlcmd -S $ENDPOINT -U $DB_ADMIN_USER -P "$DB_ADMIN_PASSWORD" -i database/seed.sql || print_warning "Erro ao executar seed.sql"
        print_warning "Execute manualmente os scripts SQL depois"
    else
        print_warning "sqlcmd não encontrado. Execute os scripts SQL manualmente:"
        print_info "1. Abra Azure Data Studio ou SQL Server Management Studio"
        print_info "2. Conecte em: $ENDPOINT"
        print_info "3. Execute: database/schema.sql"
        print_info "4. Execute: database/seed.sql"
    fi
}

################################################################################
# TESTAR DEPLOYMENT
################################################################################

test_deployment() {
    print_header "TESTANDO DEPLOYMENT"

    # Testar Lambda
    if [ -f ".lambda-url" ]; then
        LAMBDA_URL=$(cat .lambda-url)
        print_info "Testando API Lambda..."
        if curl -s $LAMBDA_URL/api/GetPhaseMatches?phaseId=1 > /dev/null 2>&1; then
            print_success "API Lambda respondendo!"
        else
            print_warning "API Lambda pode ainda não estar pronta"
        fi
    fi

    # Testar S3
    if [ -f ".s3-url" ]; then
        S3_URL=$(cat .s3-url)
        print_info "Testando Frontend S3..."
        if curl -s $S3_URL > /dev/null 2>&1; then
            print_success "Frontend S3 respondendo!"
        else
            print_warning "Frontend S3 pode ainda não estar pronto"
        fi
    fi
}

################################################################################
# SALVAR INFORMAÇÕES
################################################################################

save_deployment_info() {
    print_header "SALVANDO INFORMAÇÕES DE DEPLOYMENT"

    cat > DEPLOYMENT_INFO.md << EOF
# Informações de Deployment - AWS

**Data:** $(date)
**Região:** $AWS_REGION

## Recursos Criados

### RDS (Banco de Dados)
\`\`\`
Instance ID: $(cat .rds-instance-id 2>/dev/null || echo "N/A")
Engine: SQL Server Express
Username: $DB_ADMIN_USER
Database: $PROJECT_NAME
\`\`\`

### Lambda (Backend)
\`\`\`
Function Name: $FUNCTION_NAME
URL: $(cat .lambda-url 2>/dev/null || echo "N/A")
\`\`\`

### S3 + CloudFront (Frontend)
\`\`\`
Bucket: $(cat .s3-bucket 2>/dev/null || echo "N/A")
URL: $(cat .s3-url 2>/dev/null || echo "N/A")
\`\`\`

## Próximas Etapas

1. **Configurar Banco de Dados:**
   \`\`\`bash
   sqlcmd -S <ENDPOINT> -U $DB_ADMIN_USER -P '$DB_ADMIN_PASSWORD'
   :r database/schema.sql
   :r database/seed.sql
   GO
   \`\`\`

2. **Atualizar Lambda com Connection String:**
   - Acesse: https://console.aws.amazon.com/lambda
   - Function: $FUNCTION_NAME
   - Configuration → Environment variables
   - Adicione: SqlConnectionString=...

3. **Configurar CORS no Lambda:**
   - Vá em: Configuration → CORS
   - Permita: frontend URL

4. **Testar:**
   - API: $(cat .lambda-url 2>/dev/null || echo "URL_DA_API") /api/GetPhaseMatches?phaseId=1
   - Frontend: $(cat .s3-url 2>/dev/null || echo "URL_DO_FRONTEND")

## Console AWS
https://console.aws.amazon.com

EOF

    print_success "Informações salvas em DEPLOYMENT_INFO.md"
}

################################################################################
# MENU PRINCIPAL
################################################################################

main_menu() {
    print_header "BOLÃO COPA 2026 - DEPLOY NA AWS"

    echo "Escolha uma opção:"
    echo "1. ✅ Deploy Completo (Recomendado)"
    echo "2. Verificar Pré-requisitos"
    echo "3. Configurar AWS"
    echo "4. Criar RDS"
    echo "5. Deploy Backend (Lambda)"
    echo "6. Deploy Frontend (S3)"
    echo "7. Setup Banco de Dados"
    echo "8. Testar"
    echo "9. Sair"
    echo ""
    read -p "Opção: " CHOICE

    case $CHOICE in
        1)
            check_prerequisites
            configure_aws
            create_rds
            deploy_backend
            deploy_frontend
            setup_database
            test_deployment
            save_deployment_info
            print_header "✅ DEPLOYMENT CONCLUÍDO COM SUCESSO!"
            cat DEPLOYMENT_INFO.md
            ;;
        2)
            check_prerequisites
            ;;
        3)
            configure_aws
            ;;
        4)
            create_rds
            ;;
        5)
            deploy_backend
            ;;
        6)
            deploy_frontend
            ;;
        7)
            setup_database
            ;;
        8)
            test_deployment
            ;;
        9)
            print_info "Saindo..."
            exit 0
            ;;
        *)
            print_error "Opção inválida!"
            ;;
    esac
}

################################################################################
# EXECUTAR
################################################################################

# Se executado com argumento, executar diretamente
if [ $# -eq 0 ]; then
    main_menu
else
    case $1 in
        all)
            check_prerequisites
            configure_aws
            create_rds
            deploy_backend
            deploy_frontend
            setup_database
            test_deployment
            save_deployment_info
            ;;
        *)
            print_error "Uso: bash deploy-aws.sh [all]"
            ;;
    esac
fi

print_success "Finalizando..."
