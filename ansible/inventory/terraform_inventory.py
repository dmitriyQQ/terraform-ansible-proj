#!/usr/bin/env python3

import json
import subprocess
from pathlib import Path


# Определяем корень Terraform-проекта независимо от того,
# из какой директории запускается скрипт.
terraform_dir = Path(__file__).resolve().parents[2]


# Выполняем:
# terraform output -json containers_info
result = subprocess.run(
    [
        "terraform",
        "output",
        "-json",
        "containers_info",
    ],
    cwd=terraform_dir,
    capture_output=True,
    text=True,
    check=True,
)


# Преобразуем JSON-строку Terraform в словарь Python.
containers = json.loads(result.stdout)


# Начальная структура inventory.
inventory = {
    "_meta": {
        "hostvars": {},
    },
}


# Перебираем все контейнеры из Terraform output.
for hostname, container in containers.items():

    # Добавляем параметры подключения для конкретного хоста.
    inventory["_meta"]["hostvars"][hostname] = {
        "ansible_host": container["ip"],
        "ansible_user": "root",
        "ansible_ssh_common_args": (
            "-o ProxyJump=root@192.168.122.100"
        ),
    }

    # Один хост может входить в несколько групп.
    for group in container["groups"]:

        # Если группы ещё нет — создаём её.
        if group not in inventory:
            inventory[group] = {
                "hosts": [],
            }

        # Добавляем хост в группу.
        inventory[group]["hosts"].append(hostname)


# Возвращаем inventory в формате JSON.
print(json.dumps(inventory, indent=2))