#Контейнеризация и  DevOps приложений на примере Docker и Visual Studio Team Services


**Илья Зверев**
Logrocon Software Engineering
izverev@logrocon.com


[TOC]
## Установка пререквизитов на рабочую машину.
1. Docker Toolbox https://www.docker.com/products/docker-toolbox 
   обязательно установить **Docker Client for Windows** и **Docker Machine for Windows**
2. Putty https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

##Новый проект в VSTS

1. Необходимо авторизоваться в VSTS https://app.vsaex.visualstudio.com/me?campaign=o~msft~vscom~signin
2. Создать новый проект
3. После создания проекта выбрать опцию "or import a repository"
4. Импортировать код из  github по ссылке https://github.com/aprilix/JavaDemo

## Создание базовой сборки Java проекта на Hosted agent

1. Создадим пустой Build для нашего проекта
2. Для построения проекта целиком нам потребуется Bower, Maven
3. Сборочный таск для Bower не встроен в базовую поставку - мы установим его из marketplace
4. Для этого перейдем по ссылке https://marketplace.visualstudio.com/items?itemName=touchify.vsts-bower
5. Выберем Install, укажем аккаунт в VSTS, Confirm
6. Теперь добавим таски в Build
7. Первым - Bower. Параметры по умолчанию устроят
8. Вторым - Maven. Выберем Code Coverage Tool - JaCoCo
9. Сохраним и запустим.

##Создание Docker Окружения

1. В проекте уже есть Docker File, необходимо подготовить окружение для работы с ним
2. Нам потребуется: 
	- Build Agent с Docker для сборки Docker Образа
	- Azure Container Registry
	- Docker Host для запуска контейнера с приложением

### Создание Build Agent на основе Docker Host

1. Выполним команду заполнив параметры: ``` docker-machine create -d azure --azure-subscription-id {Azure Subscription ID} --azure-resource-group {resource group name} {vm name in all lowercase}```
2. Идентификатор вашей подписки можно взять по ссылке: https://portal.azure.com/#blade/Microsoft_Azure_Billing/SubscriptionsBlade
3. При первом обращении в консоли появится код подтверждения, его необходимо ввести в поле по ссылке https://aka.ms/devicelogin
4. Затем процесс продолжится.
5. Лайфхак, если процесс подвисает - нажмите пару раз Enter.
6. Теперь нужно настроить putty (опционально) – т.к. работать с ssh с ним будет удобнее чем с командой ```docker-machine ssh```
7. Выполним команду: ```docker-machine env {vm name in all lowercase}```
8. Сконвертируем приватный ключ лежащий в папке сертификатов виртуальной машины ```C:\Users\{user}\.docker\machine\machines\{vm name in all lowercase} ```
9. для этого откроем puttygen.exe
10. загрузим (Load) файл  ```id_rsa``` из папки сертификатов
11. Сохраним приватный ключ (Save Private Key) в той же папке с именем ```id_rsa.ppk```
12. теперь настроим соединение в putty. Запустим его.
13. введем Ip адрес нашего docker host в основную форму.
14. По дереву опций перейдем в ```Connection -> Data```
15. укажем имя пользователя: ```docker-user```
16. Теперь перейдем в ```Connection -> SSh -> Auth```
17. укажем private key который мы сохранили на шаге 11.
18. По дереву меню вернемся к форме Session. Если планируем сохранить сессию - введем ее имя и нажмем Save
19. Откроем сессию.
20. В рамках сессии мы установим весь софт, который нам необходим для сборки
21. для этого скачаем подготовленный скрипт: ``` wget https://raw.githubusercontent.com/aprilix/JavaDemo/master/AgentInstall/linuxSetup.sh```
22. сделаем его запускаемым": ````chmod +x ./linuxSetup.sh```
23. запустим его (без sudo!): ```./linuxSetup.sh``` 
24. скрипт установит весь необходимый софт включая build agent для VSTS
25. Настроим build agent:
26. ```cd Agents/a1```
27. ```./config.sh```
28. Выполняем указания мастера:
29. Соглашаемся на EULA
30. Указываем ссылку на наш аккаунт VSTS
31. Соглашаемся на авторизацию по PAT
32. Создаём и вводим PAT (в VSTS меню профиля -> My security -> Add -> Create Tocken)
33. Создаём в настройках новый Agent Pool и указываем его
34. Задаем имя агенту например ```{vm name in all lowercase}-a1```
35. Теперь настроим запуск Agent как Build Service
36. ```sudo ./svc.sh install```
37. ```sudo ./svc.sh start```
38. Агент должен стать доступным
39. Переключим нашу сборку на нового агента и проверим работоспособность

### Создание Docker host для сборки image и установки контейнеров

1. Запустим команду на локальной машине: ``` docker-machine create -d azure --azure-subscription-id {Azure Subscription ID} --azure-open-port 80 --azure-resource-group {resource group name} {other vm name in all lowercase}```
2. Проследим что команда выполнилась успешно. Она создаст второй хост с открытым портом 80 для нашего приложения
3. Выполним команду ```docker-machine env {vm name in all lowercase}```
4. Создадим в VSTS подключение к docker host.
5. Откроем https://{account}.visualstudio.com/docker-app/_admin/_services?_a=resources
6. Создадим новый endpoint с типом Docker Host
7. укажем имя для endpoint
8. Адрес - указанный в результатах команды из пункта 3
9. Ключи - нужно заполнить по соответствию из .pem файлов в папке с сертификатами машины (можно скопировать из блокнота)
10. Настройка завершена

### Создание Azure Container Registry
1. В Azure создадим новый реестр контейнеров -> https://portal.azure.com/#create/Microsoft.ContainerRegistry
2. Укажем имя реестра
3. Укажем группу ресурсов
4. Создать -> Развернуть
5. По окончанию развертывания включим админский доступ (альтернатива - Azure Active Directory)
6. Перейдем на созданный ресурс.
7. Выберем Ключи доступа
8. Пользователь Администратор - включить.
9. в VSTS создадим новое подключение к сервису контейнеров (new Docker Registry Connection)
10. Укажем имя для реестра.
11. Укажем адрес реестра в формате ```https://{registry name}.azurecr.io/v1```
12. Docker Id - имя админской учетной записи.
13. Password - один из паролей к ней.
14. Обязательно укажем свой email.
15. Настройка завершена

## Создание Docker образа с использованием DockerFile в решении
1. Добавим в нашу сборку два таска для сборки Docker
2. Первый таск - сборка нашего образа
3. В параметрах укажем наш Docker Registry.
4. Указывать можно и как Azure Container Registry, но я предпочитаю указывать как подключенный сервис
5. Поменяем Image Name - он везде должен быть в нижнем регистре и одинаковый.
6. в Advanced - укажем наш Docker Host
7. Второй таск - Action -> Push Image.
8. По аналогии с предыдущим таском указываем Image Name, Docker Registry и Docker Host
9. Сохраним и запустим наш Build
10. Проверим что включена галка CI - если нет - сохраним.

## Deployment приложения на Docker Host

1. С формы успешно выполненого Build - Создадим новое определение Release
2. Укажем имя нашего определения.
3. Укажем имя нашего окружения (например DEV)
4. Укажем пустой шаблон и включим CD режим
5. Выберем опцию Run on Agent
6. В Additional options отключим скачивание артефактов
7. Укажем наш пул со сборочным агентом в поле Deployment queue
8. добавим два Docker таска
9. Первый - запуск команды удаления предыдущего контейнера с хоста, занимающего тоже самое место (опционально)
10. Укажем Action - Run a Docker command
11. Команда ```rm -rf {container name}```
12. Указываем наш Docker Host
13. Второй таск - запуск нашего образа
14. Укажем Action -> Run Image
15. Укажем имя нашего Image по аналогии с Build
16. Укажем имя нашего контейнера ```{container name}```
17. Укажем проброс портов из Host в Container - ```80:8080```
18. Укажем Наш Docker Host
19. Сохраним определение
20. Запустим и проверим
21. CI - CD с Docker Настроен



