start-db:
    #!/usr/bin/env bash
    set -euo pipefail
    if container inspect singhsabha_db &>/dev/null; then
        container start singhsabha_db
    else
        container run -d \
            --name singhsabha_db \
            --platform linux/arm64 \
            -e POSTGRES_DB=singhsabha_db \
            -e POSTGRES_USER=singhsabha_user \
            -e POSTGRES_PASSWORD=password \
            -e PGDATA=/var/lib/postgresql/data/pgdata \
            -p 5432:5432 \
            -v singhsabha_db-data:/var/lib/postgresql/data \
            postgres:16
    fi
    until container exec singhsabha_db pg_isready -U singhsabha_user -q; do
        sleep 0.5
    done
    echo "Ready: postgresql://singhsabha_user:password@localhost:5432/singhsabha"

seed-db:
    #!/usr/bin/env bash
    set -euo pipefail

    cd singh_sabha

    mix ecto.migrate
    mix run priv/repo/seeds.exs

stop-db:
    container stop singhsabha_db

connect-db:
    container exec -it singhsabha_db psql -U singhsabha_user -d singhsabha_db
