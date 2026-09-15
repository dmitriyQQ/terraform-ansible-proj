# Terraform + Ansible проект для Proxmox

Учебный проект для практики Terraform и Ansible.

Terraform создаёт LXC-контейнеры в Proxmox, а Ansible подключается к созданным контейнерам и устанавливает на них необходимые сервисы.

В проекте используются:

- Terraform
- Proxmox VE
- LXC
- Ansible
- Nginx
- Flask
- PostgreSQL
- Prometheus
- Grafana
- Node Exporter
- Ansible Vault

---

## Схема проекта

```text
                         Terraform
                            │
                            ▼
                         Proxmox VE
                            │
          ┌─────────────────┼───────────────────┐
          │                 │                   │
          ▼                 ▼                   ▼
       web-01             db-01           monitoring-01
    Nginx + Flask       PostgreSQL       Prometheus + Grafana
    Node Exporter       Node Exporter       Node Exporter


     test-container-01            test-container-02
        Node Exporter                Node Exporter
```

После создания контейнеров Terraform передаёт информацию о них в Ansible:

```text
Terraform
    │
    ▼
terraform output
    │
    ▼
dynamic_inventory.py
    │
    ▼
Ansible
```

Ansible подключается к контейнерам через Proxmox с помощью SSH ProxyJump.

---

## Что разворачивается

### web-01

На web-контейнер устанавливаются:

- Nginx
- Flask-приложение для заметок
- Node Exporter

Nginx принимает HTTP-запросы и передаёт их Flask-приложению:

```text
Клиент
  │
  ▼
Nginx :80
  │
  ▼
Flask 127.0.0.1:5000
```

Само Flask-приложение слушает только `127.0.0.1:5000`.

Приложение позволяет:

- создавать заметки;
- просматривать заметки;
- редактировать заметки;
- удалять заметки.

Данные хранятся в PostgreSQL.

---

### db-01

На контейнер с базой данных устанавливается PostgreSQL.

Ansible:

- устанавливает PostgreSQL;
- создаёт пользователя;
- создаёт базу данных;
- создаёт таблицу `notes`;
- настраивает доступ к PostgreSQL;
- разрешает подключение с web-контейнера.

Пароль пользователя базы данных хранится в Ansible Vault.

---

### monitoring-01

На monitoring-контейнер устанавливаются:

- Prometheus
- Grafana
- Node Exporter

Prometheus собирает метрики с Node Exporter, установленных на контейнерах.

Grafana использует Prometheus как источник данных.

Также Ansible автоматически добавляет dashboard для просмотра метрик Node Exporter.

---

### test-container-01 и test-container-02

Тестовые контейнеры используются для проверки работы Ansible с несколькими хостами.

На них устанавливается Node Exporter.

---

# Terraform

Terraform отвечает за создание LXC-контейнеров в Proxmox.

Контейнеры описываются через переменную `containers`.

Пример:

```hcl
containers = {
  web-01 = {
    profile = "medium"

    network = {
      eth0 = {
        ip      = "192.168.100.10/24"
        bridge  = "vmbr1"
        gateway = "192.168.100.2"
      }
    }

    groups = [
      "web",
      "containers"
    ]
  }
}
```

Имя элемента:

```text
web-01
```

используется как hostname контейнера.

---

## Профили ресурсов

Для контейнеров можно использовать готовые профили ресурсов:

```text
small
medium
large
```

Профиль задаёт базовые значения:

- RAM;
- swap;
- количество CPU;
- размер диска.

Например:

```hcl
profile = "medium"
```

При необходимости отдельные параметры контейнера можно изменить вручную.

Например, контейнер может использовать профиль, но иметь другое количество памяти.

В таком случае настройки контейнера имеют больший приоритет, чем настройки профиля.

---

## Проверка входных данных

В Terraform добавлены проверки некоторых входных параметров.

Например, проверяются:

- количество CPU;
- минимальное количество RAM;
- имя профиля;
- формат размера диска;
- наличие root-диска, если профиль не используется.

Например, размер диска должен иметь формат:

```text
8G
16G
32G
```

Значения вроде:

```text
0G
01G
8GB
```

не проходят проверку.
[
      "web",
      "containers"
    ]
---

## Terraform outputs

Terraform передаёт Ansible информацию о созданных контейнерах.

Для этого используется output:

```text
containers_info
```

Он содержит:

- hostname;
- IP-адрес;
- Ansible-группы.

Например:

```json
{
  "web-01": {
    "ip": "192.168.100.10",
    "groups": [
      "web",
      "containers"
    ]
  }
}
```

Также Terraform передаёт адрес Proxmox-хоста:

```text
proxmox_ssh_host
```

Он используется Ansible для подключения к контейнерам через Prox[
      "web",
      "containers"
    ]yJump.

---

# Ansible

Ansible отвечает за настройку уже созданных контейнеров.

Основной playbook:

```text
ansible/site.yml
```

В проекте используются роли:

```text
node_exporter
nginx
notes_app
postgres
prometheus
grafana
```

---

## Динамический inventory

IP-адреса контейнеров не записываются вручную в Ansible inventory.

Вместо этого используется Python-скрипт:

```text
dynamic_inventory.py
```

Он выполняет:

```bash
terraform output -json
```

и получает информацию о контейнерах из Terraform.

После этого скрипт формирует inventory для Ansible.

Схема:

```text
Terraform
    │
    ▼
containers_info
    │
    ▼
dynamic_inventory.py
    │
    ▼
Ansible inventory
```

Например, для `web-01` Ansible получает:

```json
{
    "ansible_host": "192.168.100.10",
    "ansible_ssh_common_args": "-o ProxyJump=root@192.168.122.100",
    "ansible_user": "root"
}
```

Таким образом, IP контейнеров не нужно отдельно указывать в Terraform и Ansible.

---

## Подключение к контейнерам

Контейнеры находятся в отдельной сети.

Ansible-controller подключается к ним через Proxmox:

```text
Ansible-controller
        │
        ▼
     Proxmox
        │
        ▼
   LXC-контейнер
```

Для этого используется SSH ProxyJump.

Адрес Proxmox берётся из Terraform output, а не записан напрямую в Python-скрипте.

---

# Node Exporter

Node Exporter устанавливается на все контейнеры.

Архив Node Exporter сначала скачивается на Ansible-controller.

После загрузки Ansible проверяет SHA256 checksum архива.

Затем архив копируется на контейнеры:

```text
GitHub
  │
  ▼
Ansible-controller
  │
  ▼
LXC-контейнеры
```

Это было сделано потому, что при загрузке архива отдельно с каждого контейнера иногда скачивался повреждённый файл.

Также роль проверяет установленную версию Node Exporter и выполняет установку только при необходимости.

---

# Prometheus

Prometheus устанавливается похожим способом.

Ansible:

1. скачивает архив на controller;
2. проверяет checksum;
3. копирует архив на monitoring-контейнер;
4. распаковывает его;
5. устанавливает Prometheus;
6. создаёт systemd service.

Prometheus собирает метрики Node Exporter с контейнеров.

---

# Grafana

Grafana устанавливается из официального APT-репозитория.

Ключ репозитория хранится внутри Ansible-роли и копируется на контейнер перед добавлением репозитория.

Ansible также автоматически настраивает:

- Prometheus datasource;
- Node Exporter dashboard.

---

# Notes App

Notes App — небольшое Flask-приложение для работы с заметками.

Файлы приложения находятся в:

```text
ansible/roles/notes_app/files/app/
```

Пример структуры:

```text
app/
├── app.py
├── requirements.txt
├── static/
│   └── style.css
└── templates/
    ├── edit.html
    └── index.html
```

Приложение запускается отдельным systemd service.

Для него создаётся отдельный системный пользователь:

```text
notes-app
```

Код приложения находится в:

```text
/opt/notes-app
```

Python-зависимости устанавливаются в virtualenv:

```text
/opt/notes-app/venv
```

---

# PostgreSQL

Для работы с PostgreSQL используются модули Ansible из коллекции:

```text
community.postgresql
```

Ansible создаёт:

```text
database: notes
user: notes_user
table: notes
```

Также автоматически изменяются:

```text
listen_addresses
pg_hba.conf
```

IP web-сервера берётся из Ansible inventory:

```text
groups['web']
```

IP базы данных для Notes App также берётся из inventory, а не записывается напрямую в конфигурацию приложения.

---

# Ansible Vault

Пароль пользователя PostgreSQL хранится в Ansible Vault.

Файл:

```text
secrets.yml
```

не добавляется в Git.

Создать его можно командой:

```bash
ansible-vault create secrets.yml
```

Внутри используется переменная:

```yaml
db_user_passwd: "password"
```

Для запуска playbook:

```bash
ansible-playbook site.yml --ask-vault-pass
```

---

# Структура проекта

Основные файлы проекта:

```text
.
├── ansible/
│   ├── inventory/
│   │   └── dynamic_inventory.py
│   │
│   ├── roles/
│   │   ├── grafana/
│   │   ├── nginx/
│   │   ├── node_exporter/
│   │   ├── notes_app/
│   │   ├── postgres/
│   │   └── prometheus/
│   │
│   ├── requirements.yml
│   └── site.yml
│
├── modules/
│   └── lxc_container/
│       ├── main.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── versions.tf
│
├── containers.tf
├── locals.tf
├── outputs.tf
├── variables.tf
├── terraform.tfvars.example
└── README.md
```

---

# Требования

Для запуска проекта нужны:

- Proxmox VE;
- Terraform;
- Ansible;
- Python 3;
- SSH-доступ к Proxmox;
- Proxmox API token;
- LXC template Ubuntu;
- SSH public key.

Также должна быть настроена сеть, через которую LXC-контейнеры смогут работать друг с другом.

---

# Подготовка

Клонировать репозиторий:

```bash
git clone https://github.com/dmitriyQQ/terraform-ansible-proj.git
cd terraform-ansible-proj
```

Создать локальный файл с Terraform-переменными:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Заполнить необходимые значения:

```hcl
proxmox_api_url    = "..."
proxmox_api_id     = "..."
proxmox_api_secret = "..."
proxmox_ssh_host   = "..."
lxc_passwd         = "..."
ssh_public_key     = "..."
```

Также необходимо указать необходимые контейнеры в `containers`.

---

# Запуск Terraform

Инициализация:

```bash
terraform init
```

Форматирование:

```bash
terraform fmt
```

Проверка конфигурации:

```bash
terraform validate
```

Просмотр изменений:

```bash
terraform plan
```

Создание контейнеров:

```bash
terraform apply
```

После создания можно посмотреть данные, которые Terraform передаёт Ansible:

```bash
terraform output
```

или:

```bash
terraform output -json
```

---

# Установка зависимостей Ansible

Проект использует коллекцию:

```text
community.postgresql
```

Она указана в:

```text
ansible/requirements.yml
```

Установить зависимости:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

---

# Проверка Ansible inventory

Посмотреть группы:

```bash
ansible-inventory --graph
```

Посмотреть данные конкретного хоста:

```bash
ansible-inventory --host web-01
```

Проверить подключение ко всем контейнерам:

```bash
ansible all -m ping
```

При успешном подключении Ansible должен получить:

```text
ping: pong
```

от каждого контейнера.

---

# Запуск Ansible

После создания контейнеров:

```bash
cd ansible
```

Запустить playbook:

```bash
ansible-playbook site.yml --ask-vault-pass
```

После выполнения будут настроены:

```text
web-01
├── Nginx
├── Notes App
└── Node Exporter

db-01
├── PostgreSQL
└── Node Exporter

monitoring-01
├── Prometheus
├── Grafana
└── Node Exporter

test-container-01
└── Node Exporter

test-container-02
└── Node Exporter
```

---

# Повторный запуск Ansible

Проект проверялся повторным запуском Ansible.

После первого успешного выполнения:

```bash
ansible-playbook site.yml --ask-vault-pass
```

повторный запуск не должен заново изменять уже правильно настроенные сервисы.

На проверенном стенде второй запуск завершался с:

```text
failed=0
changed=0
```

на всех контейнерах.

---

# Полное пересоздание

Проект также проверялся полным удалением и повторным созданием контейнеров.

Удаление:

```bash
terraform destroy
```

Повторное создание:

```bash
terraform apply
```

После этого Ansible заново настраивал все контейнеры:

```bash
cd ansible
ansible-playbook site.yml --ask-vault-pass
```

После повторного запуска Ansible:

```text
failed=0
changed=0
```

Это использовалось для проверки того, что проект можно развернуть заново с нуля.

---

# Доступ к сервисам

## Notes App

```text
http://<IP web-01>
```

Например:

```text
http://192.168.100.10
```

---

## Prometheus

```text
http://<IP monitoring-01>:9090
```

Например:

```text
http://192.168.100.12:9090
```

---

## Grafana

```text
http://<IP monitoring-01>:3000
```

Например:

```text
http://192.168.100.12:3000
```

---

# Секреты

В Git не должны попадать:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.*
secrets.yml
.vault_pass
```

Terraform API secret и пароли задаются локально.

Пароль PostgreSQL хранится в Ansible Vault.

Terraform state также необходимо считать чувствительным файлом, так как в нём могут находиться значения переменных.

---

# Ограничения проекта

Проект рассчитан на мой учебный стенд.

Используется:

- один web-контейнер;
- один контейнер PostgreSQL;
- один monitoring-контейнер;
- один сетевой интерфейс на контейнер;
- Proxmox как SSH jump host.

Некоторые сетевые параметры зависят от моей схемы сети Proxmox и при запуске на другом стенде должны быть изменены.