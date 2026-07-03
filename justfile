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

start-bucket:
    #!/usr/bin/env bash
    set -euo pipefail
    if container inspect singhsabha_bucket &>/dev/null; then
        container start singhsabha_bucket
    else
        container run -d \
            --name singhsabha_bucket \
            --platform linux/arm64 \
            -p 8333:8333 \
            -v singhsabha_bucket-data:/data \
            chrislusf/seaweedfs server \
            -s3 \
            -s3.port=8333 \
            -dir=/data \
            -master.volumeSizeLimitMB=1024
    fi
    until curl -sf http://localhost:8333 -o /dev/null; do
        sleep 0.5
    done
    echo "Ready: http://localhost:8333"

stop-bucket:
    container stop singhsabha_bucket

create-buckets:
    #!/usr/bin/env bash
    set -euo pipefail
    mc alias set singhsabha_bucket http://localhost:8333 dev-access-key dev-secret-key 2>/dev/null || true
    mc mb -p singhsabha_bucket/singh-sabha-posters 2>/dev/null || echo "bucket already exists"

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

setup:
    just start-db
    just start-bucket
    just create-buckets
    just seed-db

stop:
    just stop-db
    just stop-bucket
