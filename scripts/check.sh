#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
project="counter-test-$(date +%s)-$$"
export APP_PORT=0

dc() {
    docker compose -p "$project" --env-file .env.example "$@"
}

cleanup() {
    code=$?
    if [ "$code" -ne 0 ]; then
        echo "Ошибка на этапе: $stage" >&2
    fi
    dc down -v --rmi local || exit 1
    exit "$code"
}

stage="запуск тестового проекта"
trap cleanup EXIT
trap 'exit 1' INT TERM
dc up -d --build --wait --wait-timeout 60

stage="проверка начального значения"
url="http://$(dc port app 8000)"
response=$(curl -fsS --max-time 5 "$url/")
echo "$response"
echo "$response" | dc exec -T app python -c \
    'import json, sys; sys.exit(json.load(sys.stdin)["count"] != 0)'
echo "Начальный счётчик равен 0"

check_count() {
    response=$(curl -fsS --max-time 5 -X "$1" "$url$2")
    echo "$response"
    printf '%s\n' "$response" | dc exec -T app python -c \
        'import json, sys; sys.exit(json.load(sys.stdin)["count"] != int(sys.argv[1]))' "$3"
}

stage="увеличение счётчика"
check_count POST /increment 1
check_count POST /increment 2

stage="пересоздание приложения"
dc up -d --no-deps --force-recreate --wait --wait-timeout 60 app
url="http://$(dc port app 8000)"
check_count GET / 2
echo "После пересоздания app счётчик равен 2"

check_status() {
    code=$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' -X "$1" "$url$2")
    echo "$1 $2 — получен $code, ожидался $3"
    test "$code" = "$3"
}

stage="проверка при остановленном Redis"
dc stop redis
check_status GET /healthz 200
check_status GET /readyz 503
check_status POST /increment 503

stage="проверка после запуска Redis"
dc start redis
curl -fsS --max-time 5 --retry 10 --retry-delay 1 "$url/readyz"
echo
check_count GET / 2
check_count POST /increment 3

stage="резервная копия Redis"
dc stop app
dc stop redis
mkdir -p backups
backup="backups/$project.tar"

dc run --rm --no-deps -T --user 0 --entrypoint tar redis \
    -C /data -cf - . > "$backup.tmp"
tar -tf "$backup.tmp"
mv "$backup.tmp" "$backup"
echo "Резервная копия сохранена в $backup"
