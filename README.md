# Terraform + Ansible проект для Proxmox

Учебный проект для практики Terraform и Ansible.

Terraform создаёт LXC-контейнеры в Proxmox, а Ansible подключается к созданным контейнерам и устанавливает на них необходимые сервисы.

В проекте используются:

* Terraform
* Proxmox VE
* LXC
* Ansible
* Python
* Nginx
* Flask
* PostgreSQL
* Prometheus
* Grafana
* Node Exporter
* Ansible Vault

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
terraform_inventory.py
    │
    ▼
Ansible
```

Ansible подключается к контейнерам через Proxmox с помощью SSH ProxyJump.

---

# Что разворачивается

## web-01

На web-контейнер устанавливаются:

* Nginx
* Flask-приложение для заметок
* Node Exporter

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

Само Flask-приложение слушает только:

```text
127.0.0.1:5000
```

Приложение позволяет:

* создавать заметки;
* просматривать заметки;
* редактировать заметки;
* удалять заметки.

Данные хранятся в PostgreSQL.

---

## db-01

На контейнер с базой данных устанавливается PostgreSQL.

Ansible:

* устанавливает PostgreSQL;
* создаёт пользователя базы данных;
* создаёт базу данных;
* создаёт таблицу `notes`;
* настраивает `listen_addresses`;
* настраивает `pg_hba.conf`;
* разрешает подключение с web-контейнера;
* запускает и включает PostgreSQL через systemd.

Пароль пользователя базы данных хранится в Ansible Vault.

---

## monitoring-01

На monitoring-контейнер устанавливаются:

* Prometheus
* Grafana
* Node Exporter

Prometheus собирает метрики с Node Exporter, установленных на контейнерах.

Grafana использует Prometheus как источник данных.

Ansible также автоматически добавляет:

* Prometheus datasource;
* dashboard для Node Exporter.

---

## test-container-01 и test-container-02

Тестовые контейнеры используются для проверки работы Ansible с несколькими хостами.

На них устанавливается Node Exporter.

---

# Terraform

Terraform отвечает за создание LXC-контейнеров в Proxmox.

Контейнеры описываются через переменную:

```text
containers
```

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

Для контейнеров можно использовать готовые профили:

```text
small
medium
large
```

Профиль задаёт базовые значения:

* количество CPU;
* RAM;
* swap;
* размер диска.

Например:

```hcl
profile = "medium"
```

При необходимости параметры отдельного контейнера можно переопределить.

Например, контейнер может использовать профиль `medium`, но иметь другое количество памяти.

Настройки самого контейнера имеют больший приоритет, чем настройки профиля.

Схема:

```text
профиль
   +
настройки контейнера
   =
итоговые параметры
```

---

## Проверка входных данных

В Terraform добавлены проверки некоторых параметров.

Проверяются:

* количество CPU;
* минимальное количество RAM;
* имя профиля;
* формат размера диска;
* наличие root-диска, если профиль не используется.

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

---

## Terraform outputs

Terraform передаёт Ansible информацию о созданных контейнерах.

Для этого используется output:

```text
containers_info
```

Он содержит:

* hostname;
* IP-адрес;
* Ansible-группы.

Пример:

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

Он используется Ansible для подключения к контейнерам через SSH ProxyJump.

Адрес Proxmox не записан напрямую в Python-скрипте inventory.

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

Для получения информации о контейнерах используется Python-скрипт:

```text
ansible/inventory/terraform_inventory.py
```

Он выполняет:

```bash
terraform output -json
```

и получает данные из Terraform.

После этого скрипт формирует inventory для Ansible.

Схема:

```text
Terraform
    │
    ▼
terraform output -json
    │
    ▼
terraform_inventory.py
    │
    ▼
Ansible inventory
```

Например, для `web-01` Ansible получает данные примерно такого вида:

```json
{
    "ansible_host": "192.168.100.10",
    "ansible_ssh_common_args": "-o ProxyJump=root@192.168.122.100",
    "ansible_user": "root"
}
```

Таким образом, IP-адреса контейнеров не нужно отдельно указывать в Terraform и Ansible.

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

Адрес Proxmox берётся из Terraform output:

```text
proxmox_ssh_host
```

---

# Node Exporter

Node Exporter устанавливается на все контейнеры.

Архив сначала скачивается на Ansible-controller.

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

Такой способ был выбран потому, что при загрузке архива отдельно на каждом контейнере иногда скачивался повреждённый файл.

Роль также проверяет установленную версию Node Exporter и выполняет установку только при необходимости.

---

# Prometheus

Prometheus устанавливается похожим способом.

Ansible:

1. скачивает архив на controller;
2. проверяет SHA256 checksum;
3. копирует архив на monitoring-контейнер;
4. распаковывает его;
5. устанавливает Prometheus;
6. создаёт systemd service;
7. запускает и включает сервис.

Prometheus собирает метрики Node Exporter с контейнеров.

---

# Grafana

Grafana устанавливается из официального APT-репозитория.

GPG-ключ репозитория хранится внутри Ansible-роли и копируется на контейнер перед добавлением репозитория.

Это позволяет не скачивать ключ повторно при каждом запуске Ansible.

Ansible также автоматически настраивает:

* Prometheus datasource;
* Node Exporter dashboard.

---

# Notes App

Notes App — небольшое Flask-приложение для работы с заметками.

Файлы приложения находятся в:

```text
ansible/roles/notes_app/files/app/
```

Структура:

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

Файлы приложения копируются в:

```text
/opt/notes-app
```

Python-зависимости устанавливаются в virtualenv:

```text
/opt/notes-app/venv
```

Версии основных Python-зависимостей закреплены в `requirements.txt`:

```text
Flask==3.1.3
psycopg2-binary==2.9.13
python-dotenv==1.2.3
```

Эти версии были взяты из уже работающего окружения приложения.

---

## Настройки подключения к PostgreSQL

Настройки приложения хранятся в:

```text
/opt/notes-app/.env
```

Файл создаётся из Ansible-шаблона:

```text
ansible/roles/notes_app/templates/env.j2
```

IP PostgreSQL не записан в шаблоне вручную.

Ansible получает первый хост из группы:

```text
db
```

и берёт его `ansible_host`.

После создания файла получается примерно:

```text
DB_HOST=192.168.100.11
DB_PORT=5432
DB_NAME=notes
DB_USER=notes_user
DB_PASSWORD=...
```

Пароль берётся из Ansible Vault.

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

IP web-сервера берётся из Ansible inventory.

---

## Зависимости Ansible

Проект использует коллекцию:

```text
community.postgresql
```

Она указана в:

```text
ansible/requirements.yml
```

В проекте используется версия:

```text
community.postgresql 4.2.0
```

Перед первым запуском необходимо установить зависимости:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

---

# Ansible Vault

Пароль пользователя PostgreSQL хранится в Ansible Vault.

Файл:

```text
ansible/secrets.yml
```

создаётся локально и не хранится в Git.

Создать его можно командой:

```bash
cd ansible
ansible-vault create secrets.yml
```

Внутри используется переменная:

```yaml
---
db_user_passwd: "your-password"
```

Для запуска playbook можно использовать:

```bash
ansible-playbook site.yml --ask-vault-pass
```

Также локально можно использовать файл:

```text
.vault_pass
```

Он также не добавляется в Git.

---

# Структура проекта

Основные файлы проекта:

```text
.
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── terraform_inventory.py
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
├── providers.tf
├── terraform.tfvars.example
├── variables.tf
├── versions.tf
├── .terraform.lock.hcl
└── README.md
```

Локальные файлы с паролями, Terraform state и реальные значения переменных в репозиторий не добавляются.

---

# Требования

Для запуска проекта нужны:

* Proxmox VE;
* Terraform;
* Ansible;
* Python 3;
* SSH-доступ к Proxmox;
* Proxmox API token;
* LXC template Ubuntu;
* SSH public key.

Также должна быть настроена сеть, через которую контейнеры смогут работать друг с другом.

---

# Подготовка Terraform

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

Также необходимо описать контейнеры в переменной:

```text
containers
```

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

Просмотр планируемых изменений:

```bash
terraform plan
```

Создание контейнеров:

```bash
terraform apply
```

После создания можно посмотреть Terraform outputs:

```bash
terraform output
```

или:

```bash
terraform output -json
```

---

# Подготовка Ansible

Перейти в директорию:

```bash
cd ansible
```

Установить необходимые Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Создать Vault-файл:

```bash
ansible-vault create secrets.yml
```

Добавить пароль пользователя PostgreSQL:

```yaml
---
db_user_passwd: "your-password"
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

Запустить основной playbook:

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

После первого успешного выполнения playbook повторный запуск:

```bash
ansible-playbook site.yml --ask-vault-pass
```

не должен заново изменять уже правильно настроенные сервисы.

На проверенном стенде второй запуск завершился без изменений:

```text
db-01               changed=0 failed=0
monitoring-01       changed=0 failed=0
test-container-01   changed=0 failed=0
test-container-02   changed=0 failed=0
web-01              changed=0 failed=0
```

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

После повторного запуска Ansible все контейнеры снова завершили выполнение с:

```text
failed=0
changed=0
```

---

# Доступ к сервисам

## Notes App

```text
http://<IP web-01>
```

Для текущей схемы сети:

```text
http://192.168.100.10
```

---

## Prometheus

```text
http://<IP monitoring-01>:9090
```

Для текущей схемы сети:

```text
http://192.168.100.12:9090
```

---

## Grafana

```text
http://<IP monitoring-01>:3000
```

Для текущей схемы сети:

```text
http://192.168.100.12:3000
```

---

# Файлы, которые не добавляются в Git

В Git не должны попадать:

```text
terraform.tfvars
terraform.tfstate
terraform.tfstate.*
ansible/secrets.yml
ansible/.vault_pass
```

Также игнорируются:

```text
.terraform/
__pycache__/
*.pyc
```

Пример Terraform-переменных хранится отдельно:

```text
terraform.tfvars.example
```

и не содержит реальных секретов.

Terraform state также не хранится в Git, так как он может содержать чувствительные данные.

---

# Ограничения проекта

Проект рассчитан на мой учебный стенд.

Используется:

* один web-контейнер;
* один контейнер PostgreSQL;
* один monitoring-контейнер;
* один сетевой интерфейс на контейнер;
* Proxmox как SSH jump host.

Некоторые сетевые параметры зависят от используемой схемы сети Proxmox и при запуске проекта на другом стенде должны быть изменены.
