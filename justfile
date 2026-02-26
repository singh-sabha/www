start-db:
    #!/usr/bin/env bash
    set -euo pipefail

    if docker inspect singhsabha-db &>/dev/null; then
        docker start singhsabha-db
    else
        docker run -d \
            --name singhsabha-db \
            -e POSTGRES_DB=singhsabha \
            -e POSTGRES_USER=singhsabha_user \
            -e POSTGRES_PASSWORD=password \
            -p 5432:5432 \
            -v singhsabha-db-data:/var/lib/postgresql/data \
            postgres:16
    fi

    until docker exec singhsabha-db pg_isready -U singhsabha_user -q; do
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
   docker stop singhsabha-db

connect-db:
    docker exec -it singhsabha-db psql -U singhsabha_user -d singhsabha
