# brdm88_microservices
Dmitry Bredikhin microservice technology study repository


Homework-32
===========

##### Базовая часть

Подготовлен кластер Kubernetes и рабочее окружение.


###### Мониторинг

С помощью Helm установлены nginx-ingress и prometheus.
```
helm install stable/nginx-ingress --name nginx

helm upgrade prom . -f custom_values.yaml --install

helm upgrade reddit-test ./reddit --install
helm upgrade staging --namespace staging ./reddit --install
helm upgrade production --namespace production ./reddit --install
```

Изучен Service Discovery и метрики **cAdvisor**. 

Запущены сервисы **kube-state-metrics** и **node-exporter**.

Сконфигурирован job в Prometheus для сбора метрик сервисов приложения, далее он разбит на отдельные job-ы для каждого сервиса.


###### Визуализация

С помощью Helm установлена **Grafana**.

При попытке установки с помощью следующей команды:
```
helm upgrade --install grafana stable/grafana \
--set "server.adminPassword=admin" \
--set "server.service.type=NodePort" \
--set "server.ingress.enabled=true" \
--set "server.ingress.hosts={reddit-grafana}"
```
тип сервиса оставался ClusterIP и соответственно не было доступа извне, в итоге установка была произведена из предварительно 
загруженного и сконфигурированного локально Chart-а (находится в папке `kubernetes/Charts`).

Сконфигурированы dashboard-ы для отображения данных мониторинга кластера Kubernetes, а также интерфейса приложения и бизнес-логики.

Настроена параметризация графиков метрик приложения для группировки данных по окружениям.

P.S. Отмечу, что в презентации была выявлена неточность: в примере на слайде 44 верным выражением для параметризации запроса 
является `{kubernetes_namespace=~"$namespace"}`.

Dashboard-ы выгружены в папку `kubernetes/monitoring/grafana-dashboards`.


###### Логирование

Развернут EFK-стек.
```
kubectl label node gke-kuber-logmon-powerful-pool-4a650a8a-2kvb elastichost=true

kubectl apply -f ./efk

helm upgrade --install kibana stable/kibana \
--set "ingress.enabled=true" \
--set "ingress.hosts={reddit-kibana}" \
--set "env.ELASTICSEARCH_URL=http://elasticsearch-logging:9200" \
--version 0.1.1
```

Рассмотрена работа с данными в Kibana.


##### Дополнительные задания

1. Настроены alert-ы на контроль доступности k8s api-сервера состояния хостов (через `custom_values.yaml`), запущен **Alertmanager** 
и настроена нотификация в персональный Slack-канал.

2. На основе манифестов созданы Helm Chart-ы для установки EFK-стека. Chart-ы находятся в папке `kubernetes/Charts/efk`.


----
----


Homework-31
===========

###### 1. Helm

Установлен **Helm Client** (версии 2.9.0), а также **Tiller**. 

Созданы Chart-ы для компонент приложения (ui, post, comment), определены шаблоны манифестов, реализованы *helper*-функции для вывода имён объектов.

Создан и параметризован Chart для приложения **Reddit**, описывающий зависимости. Выполнен тестовый деплой и проверена работа приложения.

----
По итогам выполнения заданий дали о себе знать несколько моментов, на которые стоит обратить внимание:
 * при наличии нескольких развернутых ранее балансировщиков невозможно параллельно запустить 3 релиза сервиса **ui** - судя по всему, достигается 
   лимит GCP, после того, как ранее созданные ingress-ы были удалены, проблема отпала
 * ресурсов нод класса `g1-small` едва хватает для работы с Helm, в итоге были использованы ноды `n1-standard-1`


###### 2. GitLab CI

С помощью Helm в кластер установлен GitLab CI на ноду класса `n1-standard-2`.

Создана структура проектов, загружены исходные коды сервисов приложения и Chart-ы Helm.

Настроены CI/CD Pipelines для проектов сервисов, а также динамическое создание и удаление окружений.

Настроен пайплайн для деплоя приложения на **stage** и **prod** окружения.


----
----


Homework-30
===========

###### 1. Сетевое взаимодействие

Рассмотрена работа **kube-dns**.

Сервис **ui** реконфигурирован в тип LoadBalancer, опробована работа приложения через балансировщик.

Создан Ingress для сервиса **ui**, обробована работа встроенного в GKE Ingress Controller-a в качестве L7-балансировщика.

После, тип сервиса **ui** был изменен на NodePort, перенастроен Ingress, протестирована работа приложения.

Для приложения Reddit настроена терминация TLS.
 * создан TLS сертификат и k8s-объект `secret`
 * Ingress перенастроен на прием только HTTPS трафика (для корректного применения изменений пришлось пересоздать Ingress)

Листинг команд:
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=35.186.216.99"
kubectl -n dev create secret tls ui-ingress --key tls.key --cert tls.crt
kubectl -n dev describe secret ui-ingress
kubectl -n dev delete ingress ui
kubectl -n dev apply -f ui-ingress.yml
```

Протестирована работа Network Policy.
 * Включены beta-компоненты GCP и активирован функционал NetworkPolicy
 * Создан манифест, описывающий объект `NetworkPolicy`

Листинг команд:
```
gcloud beta container clusters list
gcloud beta container clusters update kuber-reddit --zone=europe-west4-b --update-addons=NetworkPolicy=ENABLED
gcloud beta container clusters update kuber-reddit --zone=europe-west4-b --enable-network-policy

kubectl -n dev apply -f mongo-network-policy.yml
```
Проверена работа приложения. Стоит заметить, что при применении Network Policy пересоздались затрагиваемые ею pod-ы.
YAML-манифест объекта Secret добавлен в папку манифестов приложения (файл `ui-secret-ingress.yml`).


###### 2. Хранилища данных

Создан диск в Google Cloud (`gcloud compute disks create --size=25GB --zone=europe-west4-b reddit-mongo-disk`), в Deployment для MongoDB 
добавлен Volume типа `gcePersistentDisk`, протестировано сохранение данных после пересоздания pod-а с СУБД.

Рассмотрен механизм **PersistentVolume**. 
Созданы манифесты для сущностей классов `PersistentVolume` и `PersistentVolumeClaim`.

Создан манифест для StorageClass, предусматривающего использование SSD-дисков в GCP. Описан PersistentVolumeClaim для этого StorageClass.


----
----


Homework-29
===========

##### Базовая часть

На рабочую машину установлен **Minikube** версии 0.24.1 и запущен локальный кластер Kubernetes. Kubectl был установлен ранее.

Созданы манифесты для Deployment-ов и Service-ов компонент приложения Reddit, приложение развернуто в локальном кластере.

Создан кластер Kubernetes в Google Kubernetes Engine, развернуто приложение Reddit.

Опробовано использование Dashboard в GKE. При этом Service Account и конфигурация для запуска pod-а уже оказались настроены, вручную была 
необходимость создать только clusterrolebinding с помощью соответствующей команды.

`kubectl create clusterrolebinding kubernetes-dashboard  --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard`.


##### Дополнительное задание

Реализована конфигурация модуля **Terraform** для развертывания кластера GKE. Файлы конфигурации находятся в папке `kubernetes/terraform_gke`.

YAML-манифесты для описания созданных сущностей для включения Dashboard находятся в папке `kubernetes/yml_dashboard`, манифесты были выгружены 
с помощью `kubectl get` и параметра `-o yaml`.



----
----


Homework-28
===========

В рамках данной работы были выполнены задания туториала "Kubernetes The Hard way". 
Стоит отметить, что для корректной работы **etcd** потребовалось явно указать адреса хостов кластера в секции `hosts` в файле `kubernetes-csr.json` 
перед генерацией сертификата для Kubernetes API Server.

Созданы базовые конфигурации Deployment-ов для сервисов приложения Reddit, проверен запуск pod-ов.
```
#> kubectl get pods
NAME                                  READY     STATUS      RESTARTS   AGE
busybox-6f748d598-87zfr               0/1       Completed   15         4h
comment-deployment-ddb7b8849-v5g6l    1/1       Running     0          4h
mongodb-deployment-55f5c67574-5qkhz   1/1       Running     0          4h
nginx-8586cf59-p8jfr                  1/1       Running     0          4h
post-deployment-5b8fc5457c-8dpxw      1/1       Running     0          4h
ui-deployment-67d496cdb5-fq958        1/1       Running     0          4h
```

После проведения тестов кластер был удален.
Файлы конфигурации и ключи, созданные при прохождении туториала, помещены в папку `kubernetes/kubernetes_the_hard_way`.

Файл `commands.sh` содержит рабочий список команд, выполнявшихся при развертывании кластера.


----
----


Homework-27
===========

##### Базовая часть

Созданы Docker-машины для хоста `master` и хостов `worker`, развернут кластер **Docker Swarm**.
Приложение Reddit запущено в кластере, настроены ограничения размещения. Опробованы варианты масштабирования.

При добавлении в кластер дополнительной ноды (`worker`) на ней запустятся только контейнеры сервисов, у которых стоит режим деплоя `global`, 
в нашем случае это только **node-exporter**.

При изменении количества реплик сервисов на новой worker-машине запустятся контейнеры replicated-сервисов.
Собственно, видно, что replicated сервисы балансируются по доступным ресурсам. При наличии свободных нод, на которых еще не запущены контейнеры 
данного сервиса, они будут использованы в первую очередь.

Рассмотрена работа балансировки запросов к приложению.

Настроен **Rolling Update** для сервисов **ui**, **post** и **comment**.

Настроены ограничения ресурсов для сервисов и reatart policy.

Описание сервисов мониторинга было вынесено в отдельный compose-файл в рамках выполнения предыдущих заданий. 
Были добавлены атрибуты запуска некоторых сервисов мониторинга под работу в среде Docker Swarm.


----
----


Homework-25
===========

##### Базовая часть

Обновлен код микросервисов, скорректированы зависимости и Dockerfile (последние также оптимизированы) для корректной сборки образов.

Развернут EFK стек для агрегации и обработки логов. Настроена отправка логов сервисов **post** и **ui** с помощью **fluentd** драйвера 
в **elasticsearch**. Изучена работа с данными в **kibana**.

Изучена работа со структурированными логами сервиса **post**.

Изучен парсинг неструктурированных логов сервиса **ui**.
Реализованы grok-шаблоны для парсинга логов Ruby сервиса **ui**.

##### Дополнительные задания

1. Реализован дополнительный grok-шаблон для парсинга логов сервиса **ui**.

2. Развернут **Zipkin** для распределенного трейсинга приложения и изучен принцип анализа запросов к приложению. 
Для корректной работы трассировки в сервисе **post** пришлось изменить версию python с 3 на 2.

Развернут экземпляр приложения, содержащего баги, проведен анализ. Причиной долгого отображения информации о посте являлась задержка ответа 
сервиса **post**. При ревизии кода проблема (`time.sleep(3)`) была обнаружена в функции `find_post()`.


----
----


Homework-23
===========

##### Базовая часть

###### Мониторинг Docker контейнеров
 
Развернут **cAdvisor** для мониторинга Docker контейнеров. Рассмотрен сбор метрик контейнеров сервисов.


###### Визуализация метрик

Развернута **Grafana** для визуализации данных мониторинга. 

Настроены dashboard-ы для вывода информации о состоянии docker-инфраструктуры, а также об обращениях в интерфейсу приложения и 
динамике создания постов и комментариев.


###### Алертинг

Развернут **Alertmanager**, создана базовая конфигурация и опробована нотификация в чат Slack (канал #dmitry-bredikhin чата Otus DevOps Team).


##### Дополнительные задания

1. Настроен алерт на 95-й перцентиль времени ответа сервиса UI.

2. Настроена нотификация по e-mail для Alertmanager.


Образы сервисов загружены на Docker Hub. URL репозитория: https://hub.docker.com/r/brdm88/


----
----


Homework-21
===========

##### Базовая часть

Проведена реструктуризация дерева каталогов репозитория.
Создан Docker host в GCE, в Docker-контейнере из образа развернут **Prometheus** для мониторинга микросервисов.

Настроен запуск **Prometheus** вместе с микросервисами через docker-compose, изменена стратегия сборки образов сервисов. При развертывании приложения 
с помощью `docker-compose` была выявлена неработоспособность сервиса *comment* из-за отсутствующего gem-а `tzinfo-data`, он был добавлен в Gemfile.

Изучена работа healthcheck-ов для сервисов.

Развернут Node exporter для мониторинга Docker-хоста.


##### Дополнительные задания

**1. Мониторинг MongoDB с использованием экспортера**

В качестве средства мониторинга сервиса базы данных был выбран **Percona MongoDB Exporter** (https://github.com/percona/mongodb_exporter).
Произведена компиляция приложения (написано на Go), сборка Docker-образа и его загрузка в личный репозиторий на Docker Hub.
Настроен job в Prometheus и управление сервисом через docker-compose.


**2. Мониторинг сервисов с помощью blackbox экспортера**

Было решено использовать готовый docker-образ: `prom/blackbox-exporter/`.
Настроен job в Prometheus и управление сервисом через docker-compose.
Производится мониторинг доступности сервисов по протоколу HTTP.


Образы сервисов загружены на Docker Hub. URL репозитория: https://hub.docker.com/r/brdm88/


----
----


Homework-20
===========

##### Базовая часть

На тестовом сервере GitLab был создан дополнительный проект и настроены окружения **dev**, **stage** и **production** в CI Pipeline.
Опробованы варианты работы пайплайнов в различных окружениях, с условиями за создание заданий.
Опробовано использование динамического окружения для веток репозитория.


----
----


Homework-19
===========

##### Базовая часть

Предварительно была создана виртуальная машина Google Compute Engine и установлен GitLab CI с использованием Omnibus.
Создана шаблонная конфигурация CI Pipeline, создан и зарегистрирован Runner в Docker-контейнере.
Добавлен unit-тест для монолитной версии приложения Reddit.

##### Дополнительное задание


1. Автоматизация развертывания Runner-s

В версии GitLab Runner 1.1.0 появился механизм **Runners autoscale configuration**. Задействуем его.
Конфигурация проводилась в соответствии с рекомендациями в документации GitLab: https://docs.gitlab.com/runner/configuration/autoscale.html
Механизм основан на использовании Docker-Machine для управления инстансами runner-ов.

Предварительно на машине с GitLab были настроены container registry и cache server, затем запущен и зарегистрирован runner, при этом в качестве 
executor указан `docker+machine`. Для использования docker-machine в среде GCE при создании runner были указаны данные сервисного аккаунта GCP 
в формате JSON.

```
# Create container registry
docker run -d -p 6000:5000 \
    -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
    --restart always \
    --name registry registry:2

# Create cache server
docker run -it --restart always -p 9005:9000 \
    -v /.minio:/root/.minio \
    -v /export:/export \
    --name minio \
    minio/minio:latest server /export

# Run Docker container from image (for using with docker-machine)
docker run -d --name gitlab-runner --restart always \
    -e GOOGLE_APPLICATION_CREDENTIALS=/etc/gitlab-runner/gce-docker.json \
    -v /srv/gitlab-runner/config:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    gitlab/gitlab-runner:latest
```

Заданы следующие параметры конфигурации runner-a (файл `config.toml`):
```
# config.toml file contents
concurrent = 5
check_interval = 0

[[runners]]
  name = "brdm88-autoscale-runner"
  url = "http://<gitlab_ip>"
  token = "<runner_token>"
  executor = "docker+machine"
  limit = 10
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
  [runners.cache]
    type = "s3"
    ServerAddress = "gitlab_ip:9005"
    AccessKey = "<cache_server_access_key>"
    SecretKey = "cache_server_secret_key"
    BucketName = "runner"
    Insecure = true
  [runners.machine]
    IdleCount = 0
    IdleTime = 60
    MachineDriver = "google"
    MachineName = "runner-autoscale-%s"
    MachineOptions = [
      "google-project=docker-194323",
      "google-machine-type=g1-small",
      "google-machine-image=ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20180405",
      "google-tags=default-allow-ssh",
      "google-zone=europe-west2-a",
      "google-use-internal-ip=true"
    ]
    OffPeakTimezone = ""
    OffPeakIdleCount = 0
    OffPeakIdleTime = 0

```
В качестве MachineDriver-а задан Google Compute Engine и текущий проект. После этого runner перезапущен с новой конфигурацией.
В рамках данной задачи для наглядности параметр `IdleCount` задан в 0, чтобы runner-ы стартовали и уничтожались непосредственно под job-ы.


2. Интеграция с чатом Slack

Добавлены нотификации о коммитах в репозиторий и об изменениях в CI Pipeline в канал #dmitry-bredikhin чата DevOps Team Otus.


----
----


Homework-17
===========

##### Часть 1. Сети в Docker

В рамках данного задания была изучена работа различных сетевых драйверов в Docker: *none, host, bridge*.

При запуске контейнера в сетевом пространстве хоста вывод команды `ifconfig` на docker-хосте и в контейнере в части конфигурации сетевых интерфейсов 
совпадает.

При попытке запуска в сетевом пространстве хоста нескольких контейнеров, слушающих один и тот же сетевой порт, работать будет только первый, 
остальные же завершатся вскоре после запуска, т.к. процесс, который должен работать на (уже занятом) порту, не сможет открыть его.

При запуске контейнера с null-драйвером на docker-хосте создается сетевой namespace для контейнера, где есть только loopback-интерфейс.
При запуске контейнера с host-драйвером отдельный сетевой namespace не создается, контейнер работает в default namespace.

Сервисы проекта были развернуты в двух отдельных user-defined bridge-сетях, с целью изоляции БД от frontend-интерфейса на сетевом уровне.

Исследовано состояние сетевого стека docker-хоста при нескольких созданных bridge-сетях.

Листинг консоли:

```bash
## List Docker networks
$> docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
b76327c711dc        back_net            bridge              local
d93a2377b126        bridge              bridge              local
52fbacc35850        front_net           bridge              local
0ff861fe7b88        host                host                local
d6248a3ccb9a        none                null                local
61440a175b06        reddit              bridge              local

## List brdige interfaces, there's no item for default bridge
$> ifconfig|grep br
br-52fbacc35850 Link encap:Ethernet  HWaddr 02:42:7d:76:54:99
br-61440a175b06 Link encap:Ethernet  HWaddr 02:42:96:8c:09:cd
br-b76327c711dc Link encap:Ethernet  HWaddr 02:42:d1:c7:d2:d3

## Backend network bridge
$> brctl show br-b76327c711dc
bridge name       bridge id               STP enabled   interfaces
br-b76327c711dc   8000.0242d1c7d2d3       no            veth5ca5fdf
                                                        veth72657ce
                                                        vethd121299
## Frontend network bridge
$> brctl show br-52fbacc35850
bridge name       bridge id               STP enabled   interfaces
br-52fbacc35850   8000.02427d765499       no            veth246c7da
                                                        veth6ac4a79
                                                        vetha7a98ed
## 'Reddit' network bridge - empty
$>  brctl show br-61440a175b06
bridge name       bridge id               STP enabled   interfaces
br-61440a175b06   8000.0242968c09cd       no

## iptables 'nat' table
$> iptables -t nat -L -n -v
.....
Chain POSTROUTING (policy ACCEPT 83 packets, 5043 bytes)
 pkts bytes target     prot opt in      out               source               destination
    2   100 MASQUERADE  all  --  *      !br-52fbacc35850  10.0.1.0/24          0.0.0.0/0
    0     0 MASQUERADE  all  --  *      !br-b76327c711dc  10.0.2.0/24          0.0.0.0/0
    0     0 MASQUERADE  all  --  *      !br-61440a175b06  172.18.0.0/16        0.0.0.0/0
 4079  250K MASQUERADE  all  --  *      !docker0          172.17.0.0/16        0.0.0.0/0
    0     0 MASQUERADE  tcp  --  *      *                 10.0.1.2             10.0.1.2             tcp dpt:9292

Chain DOCKER (2 references)
 pkts bytes target     prot opt in                out     source               destination
    0     0 RETURN     all  --  br-52fbacc35850   *       0.0.0.0/0            0.0.0.0/0
    0     0 RETURN     all  --  br-b76327c711dc   *       0.0.0.0/0            0.0.0.0/0
    0     0 RETURN     all  --  br-61440a175b06   *       0.0.0.0/0            0.0.0.0/0
    0     0 RETURN     all  --  docker0           *       0.0.0.0/0            0.0.0.0/0
    5   260 DNAT       tcp  --  !br-52fbacc35850  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:9292 to:10.0.1.2:9292

$> ps ax|grep docker-proxy|grep -v grep
..... /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 9292 -container-ip 10.0.1.2 -container-port 9292
```


##### Часть 2. docker-compose

В репозиторий добавлен конфигурационный файл `docker-compose.yml`, где заданы параметры docker-инфраструктуры проекта.
Сервисы приложения работают в двух подсетях.

Через переменные окружения параметризованы следующие данные: 

 * пользователь docker-репозитория
 * версии сервисов
 * порт web-интерфейса

Пример задания значений переменных: файл `.env.example`
Стоит заметить, что при изменении порта, по которому доступно приложение снаружи, в нашем случае также необходимо скорректировать правило файервола 
в GCE VPC Network для разрешения трафика на соответствующий порт.


###### Базовое имя проекта

Docker-compose присваивает всем создаваемым сущностям имена, имеющие в качестве префика базовое имя, которое по умолчанию формируется на основе 
имени директории проекта. 
Для его изменения необходимо задать значение переменной Compose CLI `COMPOSE_PROJECT_NAME`, либо же использовать ключ `-p` при запуске docker-compose, 
например, `docker-compose -p <project_name> <command>`.

###### .override-файл

Создан файл `docker-compose.override.yml`, реализующий следующее:

 * возможность изменения исходного кода приложения без пересборки образов сервисов
 * запуск web-сервера puma в отладочном режиме (`--debug -w 2`)

Для реализации первой возможности применено монтирование каталога с кодом сервиса внутрь контейнера. Предварительно необходимо скопировать код 
приложения в соответствующую директорию на docker host:
```bash
docker-machine scp -r ./comment/ docker-user@docker-host:~/reddit
docker-machine scp -r ./post-py/ docker-user@docker-host:~/reddit
docker-machine scp -r ./ui/ docker-user@docker-host:~/reddit
```

Для реализации второй возможности применен override директивы `command`.

Для использования нескольких файлов конфигурации docker-compose необходимо указать их в параметре `-f` при запуске `docker-compose up`.
В случае наличия файла `docker-compose.override.yml` он по умолчанию будет учитываться при запускеdocker-compose, для его исключения из конфигурации 
необходимо явное задание использования только одного файла конфигурации.

----
P.S. Файлы shell-команд, используемых для выполнения заданий, размещены в директории **scripts** репозитория.


----
----


Homework-16
===========

##### Описание директорий репозитория:

 **docker-monolith** - наработки из предыдущих заданий
 
 **reddit-microservices** - код приложения в микросервисной архитектуре. 

В рамках данного задания созданы Dockerfile для сервисов **post**, **comment** и **ui**. 
Выполнена оптимизация Dockerfile для уменьшения размера итоговых образов, включающая в себя:

 * Объединение в цепочки shell-команд, запускаемых с помощью `RUN`, для уменьшения числа промежуточных слоев
 * Корректировка последовательности команд работы с файлами (для предотвращения cache miss)
 * Использование более компактных базовых образов
 * Удаление кэшированных данных пакетного менеджера
 
Произведена сборка образов и запуск контейнеров сервисов.

Было опробовано указание альтернативных сетевых алиасов при запуске контейнеров без пересоздания образов, ниже приведен листинг команд:

```
docker run -d --network=reddit --network-alias=alt_post_db --network-alias=alt_comment_db \
-v reddit_db:/data/db \
mongo:latest

docker run -d --network=reddit --network-alias=alt_post \
--env POST_DATABASE_HOST=alt_post_db \
brdm88/post:1.0 

docker run -d --network=reddit --network-alias=alt_comment \
--env COMMENT_DATABASE_HOST=alt_comment_db \
brdm88/comment:1.0

docker run -d --network=reddit -p 9292:9292 \
--env POST_SERVICE_HOST=alt_post --env COMMENT_SERVICE_HOST=alt_comment \
brdm88/ui:1.0
```

Файл `build-cmds.sh` содержит рабочие команды для сборки образов и запуска контейнеров.
 
Для сервисов **comment** и **ui** были собраны образы на базе **Alpine Linux** с минимальным набором пакетов, в репозитории - переработанные Dockerfile.

Размеры образов составили соответственно 146 и 206 МБ.

Для максимального уменьшения размера конечного образа целесообразно применить multi-stage builds. Данная практика максимально эффективна для 
приложений на компилируемых языках программирования. В нашем случае код приложения написан на интерпретируемых языках Python и Ruby, 
однако некоторые gem-ы (а именно, `bson_ext`) имеют код на языке C. Build-окружение для него можно оставить только в образе стадии сборки, 
а в production-образ поместить поместить уже собранные бинарные файлы. При этом придется использовать разные наборы gem-ов для разных стадий.


----
----


Homework-15
===========

##### Общие сведения.

Предварительно на рабочую машину была установлена docker-machine версии 0.14.0.
Создана конфигурация для сборки docker-образа для приложения reddit. Произведена сборка образа при помощи `docker build`, а также его загрузка 
в репозиторий на **Docker Hub**.

Скрипты создания хоста docker-machine и правила файервола для Puma находятся в директории **config-scripts**.
Dockerfile и сопутствующие файлы конфигурации для создания образа находаятся в директории **build-reddit-image**.


----
----


Homework-14
===========

##### Общие сведения.

В рамках выполнения данного задания была произведена установка Docker version 18.02.0-ce-rc2 из официального репозитория.
Проведено тестирование запуска и останова контейнеров в различных режимах (`docker run`, `docker start`, `docker attach`, `docker exec`, `docker stop`); 
создания образов из контейнеров (`docker commit`), удаления контейнеров и образов (`docker rm`, `docker rmi`) с различными условиями.

В файле **docker-1.log** приведен вывод команды `docker images` после проведения ряда тестов.

##### Дополнительное задание.

Исследовано различие вывода команды `docker inspect` для образа и для контейнера, детали описаны в файле **docker-1.log**.
