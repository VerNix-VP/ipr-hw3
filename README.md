## ДЗ по ИПР

Условие дз доступно по [ссылке](https://github.com/Nikfilk2030/missing_semester_hse_cs/blob/main/2026/amcs/year_1/hw_3/README.md)

## Запуск

Нужны Docker с Compose и curl. Все команды выполняются из корня репозитория.

Для запуска с Redis:
```sh
docker compose --env-file .env.example up -d --build --wait
curl http://127.0.0.1:8080/
curl -X POST http://127.0.0.1:8080/increment
docker compose --env-file .env.example down
```

Порт и приветствие задаются в `.env.example`. В моём примере `APP_PORT=8080`, а `GREETING=Hello, Docker!`. Если изменить порт, его нужно поменять и в адресе для `curl`.

## Запуск варианта с одним сервисом (6 баллов)

```sh
docker compose --env-file .env.example -f compose.level6.yaml up -d --build
curl -X POST http://127.0.0.1:8080/increment
docker compose --env-file .env.example -f compose.level6.yaml down
docker compose --env-file .env.example -f compose.level6.yaml up -d
curl http://127.0.0.1:8080/
docker compose --env-file .env.example -f compose.level6.yaml down
```

## Что я проверил

- **4 балла.** Запустил один контейнер с приветствием «Привет». Первый запрос вернул 0, после двух POST счётчик дошёл до 2. Ответы и логи сохранил в `level4.txt`.
- **6 баллов.** Увеличил счётчик до 1 и удалил контейнер через `docker compose down`. После запуска изменился `hostname`, а значение осталось 1. Данные сохранились в именованном томе. Ответ нового контейнера — в `level6.txt`.
- **8 баллов.** Подключил Redis. После удаления и повторного запуска обоих контейнеров счётчик сохранил значение 2. Когда остановил только Redis, `/healthz` вернул 200, а `/readyz` и `POST /increment` вернули 503. Запустил Redis снова: приложение вернуло 2, а следующий POST — 3. Команды и ответы — в `level8.txt`.
- **10 баллов.** Через `docker inspect` проверил UID 10001, корневую файловую систему только для чтения и лимиты в 256 МиБ и одно ядро CPU. Два запуска автоматической проверки подряд прошли успешно. Вывод — в `level10.txt`.

## Как запустить автоматическую проверку

```sh
./scripts/check.sh
```

Скрипт создаёт отдельный Compose-проект с пустым томом. После проверок он останавливает приложение и Redis, сохраняет каталог данных Redis в архив в `backups/` и удаляет тестовый проект вместе с томом.
