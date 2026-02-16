# Deploy e Rollback ECS - Projeto BIA

## Visão Geral

Scripts para deploy versionado e rollback no ECS usando commit hash do Git como identificador de versão.

## Arquivos

- **deploy-ecs.sh** - Deploy de nova versão
- **rollback-ecs.sh** - Rollback para versão anterior

## Pré-requisitos

- Docker instalado e rodando
- AWS CLI configurado
- Git repository inicializado
- Permissões IAM para ECR e ECS
- jq instalado

## Deploy

### Uso Básico

```bash
./deploy-ecs.sh
```

### O que o script faz

1. Captura o commit hash atual do Git (ex: `786a8c1`)
2. Faz build da imagem Docker
3. Faz push para ECR com duas tags:
   - Tag do commit: `207206091460.dkr.ecr.us-east-1.amazonaws.com/bia:786a8c1`
   - Tag latest: `207206091460.dkr.ecr.us-east-1.amazonaws.com/bia:latest`
4. Cria nova task definition com a imagem versionada
5. Atualiza o service `service-bia` no cluster `bia`
6. Aguarda o deploy completar

### Exemplo de Saída

```
=== Deploy BIA com Versionamento ===
Commit Hash: 786a8c1
Fazendo login no ECR...
Building imagem Docker...
Tagging imagem...
Pushing para ECR...
Buscando task definition atual...
Criando nova task definition com imagem 786a8c1...
Nova Task Definition: arn:aws:ecs:us-east-1:207206091460:task-definition/task-def-bia:19
Atualizando service...
Aguardando deploy completar...
✅ Deploy concluído! Versão: 786a8c1
```

## Rollback

### Uso Básico

```bash
./rollback-ecs.sh
```

### O que o script faz

1. Lista as últimas 10 task definitions disponíveis
2. Mostra qual está atualmente em uso
3. Permite escolher para qual versão voltar
4. Atualiza o service para a task definition escolhida
5. Aguarda o rollback completar

### Exemplo de Saída

```
=== Rollback BIA ===
Buscando versões disponíveis...

Últimas versões disponíveis:

1. task-def-bia:19 - 207206091460.dkr.ecr.us-east-1.amazonaws.com/bia:786a8c1 (ATUAL)
2. task-def-bia:18 - 207206091460.dkr.ecr.us-east-1.amazonaws.com/bia:latest
3. task-def-bia:17 - 207206091460.dkr.ecr.us-east-1.amazonaws.com/bia:abc1234

Digite o número da versão para rollback (ou 0 para cancelar): 2

Fazendo rollback para: task-def-bia:18
Aguardando rollback completar...
✅ Rollback concluído! Versão: 18
```

## Vantagens

- ✅ **Versionamento claro** - Cada deploy tem commit hash único
- ✅ **Rastreabilidade** - Fácil identificar qual código está rodando
- ✅ **Rollback rápido** - Sem rebuild, apenas troca de task definition
- ✅ **Histórico completo** - Todas as versões ficam registradas no ECS
- ✅ **Não interfere** - Mantém pipeline atual intacto

## Configuração

### Variáveis (deploy-ecs.sh)

```bash
CLUSTER="bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
ECR_REPO="207206091460.dkr.ecr.us-east-1.amazonaws.com/bia"
REGION="us-east-1"
```

### Variáveis (rollback-ecs.sh)

```bash
CLUSTER="bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
REGION="us-east-1"
```

## Troubleshooting

### Erro: "git rev-parse: not a git repository"
- Certifique-se de estar em um repositório Git
- Execute `git init` se necessário

### Erro: "docker: command not found"
- Instale o Docker
- Verifique se o serviço está rodando: `systemctl status docker`

### Erro: "Unable to locate credentials"
- Configure AWS CLI: `aws configure`
- Ou use IAM role da instância EC2

### Erro: "denied: Your authorization token has expired"
- Faça login novamente no ECR
- O script já faz isso automaticamente

## Notas

- O script de deploy sempre cria uma **nova revisão** da task definition
- O rollback **não deleta** task definitions antigas
- Todas as configurações (CPU, memória, secrets) são mantidas
- O deploy usa **rolling update** (minimumHealthyPercent: 0, maximumPercent: 100)
