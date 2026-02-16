#!/bin/bash
set -e

CLUSTER="bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
ECR_REPO="207206091460.dkr.ecr.us-east-1.amazonaws.com/bia"
REGION="us-east-1"

echo "=== Deploy BIA com Versionamento ==="

COMMIT_HASH=$(git rev-parse --short HEAD)
echo "Commit Hash: ${COMMIT_HASH}"

echo "Fazendo login no ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_REPO}

echo "Building imagem Docker..."
docker build -t bia:${COMMIT_HASH} .

echo "Tagging imagem..."
docker tag bia:${COMMIT_HASH} ${ECR_REPO}:${COMMIT_HASH}
docker tag bia:${COMMIT_HASH} ${ECR_REPO}:latest

echo "Pushing para ECR..."
docker push ${ECR_REPO}:${COMMIT_HASH}
docker push ${ECR_REPO}:latest

echo "Buscando task definition atual..."
TASK_DEF=$(aws ecs describe-task-definition --task-definition ${TASK_FAMILY} --region ${REGION})

echo "Criando nova task definition com imagem ${COMMIT_HASH}..."
NEW_TASK_DEF=$(echo $TASK_DEF | jq --arg IMAGE "${ECR_REPO}:${COMMIT_HASH}" \
  '.taskDefinition | .containerDefinitions[0].image = $IMAGE | del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')

NEW_TASK_ARN=$(aws ecs register-task-definition --region ${REGION} --cli-input-json "$NEW_TASK_DEF" | jq -r '.taskDefinition.taskDefinitionArn')
echo "Nova Task Definition: ${NEW_TASK_ARN}"

echo "Atualizando service..."
aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --task-definition ${NEW_TASK_ARN} --region ${REGION} > /dev/null

echo "Aguardando deploy completar..."
aws ecs wait services-stable --cluster ${CLUSTER} --services ${SERVICE} --region ${REGION}

echo "✅ Deploy concluído! Versão: ${COMMIT_HASH}"
