# 🚀 Deploy Automático no AWS

Este guia explica como usar o script `deploy-aws.sh` para fazer deploy da aplicação **Bolão Copa 2026** na AWS.

## 📋 Pré-requisitos

### No seu notebook (Ubuntu/Linux):

```bash
# 1. Node.js 18+
node --version

# 2. .NET 8 SDK
dotnet --version

# 3. Git
git --version

# 4. AWS CLI (instalado automaticamente pelo script)
```

### Conta AWS:

1. Criar conta em: https://aws.amazon.com
2. Usar cartão de crédito (não vai cobrar - free tier)
3. Obter Access Key ID e Secret Access Key:
   - Acesse: https://console.aws.amazon.com
   - Click no seu usuário (canto superior direito)
   - "My Security Credentials"
   - "Create access key"

## 🎯 Passo a Passo

### 1️⃣ Clonar o Repositório

```bash
cd ~
git clone https://github.com/SEU-USUARIO/bolao-copa-2026.git
cd bolao-copa-2026
```

### 2️⃣ Executar o Script (Opção Automática - RECOMENDADO)

```bash
# Opção A: Menu interativo (escolhe cada etapa)
bash deploy-aws.sh

# Opção B: Deploy completo (não precisa confirmar)
bash deploy-aws.sh all
```

### 3️⃣ Seguir as Instruções

O script vai:

1. ✅ Verificar pré-requisitos (Node, .NET, Git)
2. ✅ Instalar AWS CLI (se não tiver)
3. ✅ Configurar AWS CLI (vai pedir suas credenciais)
4. ✅ Criar RDS (banco de dados SQL Server)
5. ✅ Deploy backend (AWS Lambda)
6. ✅ Deploy frontend (AWS S3 + CloudFront)
7. ✅ Configurar banco de dados
8. ✅ Testar tudo

### 4️⃣ Arquivo DEPLOYMENT_INFO.md

Após o script terminar, ele cria um arquivo `DEPLOYMENT_INFO.md` com:

- ✅ URL da API (Lambda)
- ✅ URL do Frontend (S3)
- ✅ Dados de conexão do banco
- ✅ Próximas etapas

---

## 🔧 Uso Manual (Passo a Passo)

Se preferir executar cada comando manualmente:

```bash
# 1. Verificar pré-requisitos
node --version
dotnet --version
git --version

# 2. Configurar AWS
aws configure
# Adicionar: Access Key ID, Secret Access Key, Region (us-east-1)

# 3. Clonar projeto
git clone https://github.com/SEU-USUARIO/bolao-copa-2026.git
cd bolao-copa-2026

# 4. Criar RDS
aws rds create-db-instance \
  --db-instance-identifier bolao-copa-2026 \
  --db-instance-class db.t3.micro \
  --engine sqlserver-express \
  --master-username admin \
  --master-user-password "SenhaForte@123456!" \
  --allocated-storage 20 \
  --region us-east-1

# 5. Deploy Backend
cd backend
dotnet tool install -g Amazon.Lambda.Tools
dotnet restore
dotnet build --configuration Release
dotnet lambda deploy-function --function-name bolao-copa-functions --region us-east-1

# 6. Deploy Frontend
cd ../frontend
npm install
npm run build
aws s3 mb s3://bolao-copa-frontend-$(date +%s) --region us-east-1
aws s3 cp build/ s3://bolao-copa-frontend-xxxxx/ --recursive --region us-east-1

# 7. Configurar Banco de Dados
# Obter endpoint do RDS
aws rds describe-db-instances --db-instance-identifier bolao-copa-2026 --region us-east-1

# Conectar e executar scripts
sqlcmd -S <ENDPOINT> -U admin -P "SenhaForte@123456!"
# :r database/schema.sql
# :r database/seed.sql
```

---

## 💰 Custos Estimados (Free Tier)

| Serviço | Free Tier | Depois |
|---------|-----------|--------|
| Lambda | 1M req/mês | $0.20/1M |
| RDS | 750h/mês | $0.27/h |
| S3 | 5 GB | $0.023/GB |
| CloudFront | 1 TB/mês | $0.085/GB |
| **TOTAL** | **$0** | **~$10-20/mês** |

---

## ⚠️ Troubleshooting

### Erro: "aws: command not found"
```bash
# O script instala automaticamente, mas se não funcionar:
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Erro: "SubscriptionNotFound"
```bash
# Verificar e configurar AWS novamente
aws configure
aws sts get-caller-identity
```

### RDS demora muito
- Isso é normal! RDS leva 10-15 minutos
- Você pode continuar com outras etapas enquanto espera
- Monitorar em: https://console.aws.amazon.com/rds

### Lambda deploy falha
```bash
# Criar role IAM primeiro
aws iam create-role --role-name lambda-role \
  --assume-role-policy-document file://trust-policy.json
```

### S3 bucket já existe
```bash
# Criar com timestamp único
S3_BUCKET="bolao-copa-$(date +%s)"
aws s3 mb s3://$S3_BUCKET --region us-east-1
```

---

## 🎯 Arquitetura

```
┌─────────────────────────────────────────────┐
│            AWS - Bolão Copa 2026            │
├─────────────────────────────────────────────┤
│                                             │
│  Frontend (React)                           │
│  └─→ AWS S3 + CloudFront                    │
│      └─→ https://bucket.s3-website...      │
│                                             │
│  Backend (.NET 8)                           │
│  └─→ AWS Lambda                             │
│      └─→ https://xxx.lambda-url...         │
│                                             │
│  Database (SQL Server)                      │
│  └─→ AWS RDS                                │
│      └─→ bolao-copa-2026.xxx.rds...        │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 📊 Monitoramento

Após o deploy, monitorar em:

- **Lambda**: https://console.aws.amazon.com/lambda
- **RDS**: https://console.aws.amazon.com/rds
- **S3**: https://console.aws.amazon.com/s3
- **CloudWatch**: https://console.aws.amazon.com/cloudwatch

---

## 🔄 Atualizar Código

Para atualizar o código após mudanças:

```bash
# 1. Fazer push para GitHub
git add .
git commit -m "Updates"
git push

# 2. Puxar no Ubuntu
git pull

# 3. Re-executar o script ou apenas:
# Backend
cd backend
dotnet build --configuration Release
dotnet lambda deploy-function --function-name bolao-copa-functions --region us-east-1

# Frontend
cd ../frontend
npm run build
aws s3 cp build/ s3://bolao-copa-frontend-xxxxx/ --recursive --region us-east-1
```

---

## ✅ Checklist Pós-Deploy

- [ ] RDS criado e disponível
- [ ] Backend deployado (Lambda)
- [ ] Frontend deployado (S3)
- [ ] Scripts SQL executados (schema + seed)
- [ ] Testou API com curl
- [ ] Testou frontend no navegador
- [ ] Vê os jogos da Rodada 2
- [ ] Consegue ver ranking com participantes

---

## 📞 Suporte

Dúvidas? Consulte:

1. Logs do Lambda:
   ```bash
   aws logs tail /aws/lambda/bolao-copa-functions --follow
   ```

2. CloudWatch:
   https://console.aws.amazon.com/cloudwatch

3. AWS CLI docs:
   ```bash
   aws rds help
   aws lambda help
   aws s3 help
   ```

---

**Status**: ✅ Pronto para deploy!

Desenvolvido com ❤️ para facilitar sua vida 🚀
