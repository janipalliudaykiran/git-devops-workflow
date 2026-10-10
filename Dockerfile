
FROM python:3.13-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN useradd --create-home --uid 10001 appuser

COPY --chown=appuser:appuser app/ ./app/

USER appuser

CMD ["python", "app/app.py"]

