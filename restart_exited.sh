#!/bin/bash

# Получаем список ID контейнеров в состоянии Exited
exited_containers=$(docker ps -f "status=exited" --format "{{.ID}}")

if [ -z "$exited_containers" ]; then
  echo "Нет упавших контейнеров."
else
  echo "Перезапускаем следующие контейнеры: $exited_containers"
  for container_id in $exited_containers; do
    docker restart "$container_id"
  done
fi
