# # Builder
# FROM python:3.13-slim-bookworm AS builder

# # copy the uv and vux directly from official image
# COPY --from=docker.io/astral/uv:0.12.13 /uv /uvx /bin/

# # check them 
# ENV UV_COMPILE_BYTECODE=1 \
#     UV_LINK_MODE=copy \
#     UV_PYTHON_DOWNLOADS=0 \
#     UV_NO_DEV=1 \
#     PYTHONNUNBUFFERED=1 \
#     PYTHONDONTWRITEBYTECODE=1

# WORKDIR /app

# # copy only dependency metadata first.
# COPY  pyproject.toml uv.lock ./

# RUN --mount=type=cache,target=/root/.cache.uv uv sync --locked --no-install-project --no-dev

# COPY main.py .

# # Runtime
# FROM python:3.13-slim-bookworm AS runtime

# RUN groupadd --system --gid 10001 app  && useradd --system --uid 10001 --gid 10001 --no-create-home --shell /usr/sbin/nologin app

# # create the work directory app
# WORKDIR /app

# # copy the virtual envrionment and app
# COPY --from=builder --chown=app:app /app/.venv /app/.venv
# COPY --from=builder --chown=app:app /app/main.py /app/main.py

# ENV PATH="/app/.venv/bin:$PATH" \
#     PYTHONDONTWRITEBYTECODE=1 \
#     PYTHONNUNBUFFERED=1 \
#     PYTHONHASHSEED=random

# EXPOSE 9000

# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "9000"]

FROM dhi.io/python:3.13-dev AS builder

COPY --from=docker.io/astral/uv:0.12.13 /uv /uvx /bin/

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_NO_DEV=1 \
    PYTHONNUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY pyproject.toml uv.lock ./

RUN --mount=type=cache,target=/root/.cache/uv uv sync --locked --no-install-project --no-dev

COPY main.py /app/main.py

# Runtime

FROM dhi.io/python:3.13

WORKDIR /app

COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/main.py /app/main.py

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONNUNBUFFERED=1 \
    PYTHONHASHSEED=random

EXPOSE 9000

CMD ["uvicorn","main:app","--host","0.0.0.0","--port","9000"]