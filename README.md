# brdm88_microservices
Dmitry Bredikhin microservice technology study repository


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
