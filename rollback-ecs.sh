#!/bin/bash
set -e

CLUSTER="bia"
SERVICE="service-bia"
TASK_FAMILY="task-def-bia"
REGION="us-east-1"

echo "=== Rollback BIA ==="

echo "Buscando versões disponíveis..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix ${TASK_FAMILY} --sort DESC --max-items 10 --region ${REGION} | jq -r '.taskDefinitionArns[]')

CURRENT_TASK=$(aws ecs describe-services --cluster ${CLUSTER} --services ${SERVICE} --region ${REGION} | jq -r '.services[0].taskDefinition')

echo ""
echo "Últimas versões disponíveis:"
echo ""

i=1
declare -A TASK_MAP
for task in $TASK_DEFS; do
  REVISION=$(echo $task | grep -oP ':\K[0-9]+$')
  IMAGE=$(aws ecs describe-task-definition --task-definition $task --region ${REGION} | jq -r '.taskDefinition.containerDefinitions[0].image')
  
  if [[ "$task" == "$CURRENT_TASK" ]]; then
    echo "$i. task-def-bia:${REVISION} - ${IMAGE} (ATUAL)"
  else
    echo "$i. task-def-bia:${REVISION} - ${IMAGE}"
  fi
  
  TASK_MAP[$i]=$REVISION
  ((i++))
done

echo ""
read -p "Digite o número da versão para rollback (ou 0 para cancelar): " choice

if [[ $choice -eq 0 ]]; then
  echo "Rollback cancelado."
  exit 0
fi

if [[ -z "${TASK_MAP[$choice]}" ]]; then
  echo "❌ Opção inválida!"
  exit 1
fi

SELECTED_REVISION="${TASK_MAP[$choice]}"
SELECTED_TASK="${TASK_FAMILY}:${SELECTED_REVISION}"

echo ""
echo "Fazendo rollback para: ${SELECTED_TASK}"

aws ecs update-service --cluster ${CLUSTER} --service ${SERVICE} --task-definition ${SELECTED_TASK} --region ${REGION} > /dev/null

echo "Aguardando rollback completar..."
aws ecs wait services-stable --cluster ${CLUSTER} --services ${SERVICE} --region ${REGION}

echo "✅ Rollback concluído! Versão: ${SELECTED_REVISION}"
