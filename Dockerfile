FROM mongo:6.0

COPY replica.key /data/replica.key

RUN chmod 400 /data/replica.key

RUN chown 999:999 /data/replica.key