# Post service Dockerfile

#FROM python:3.6.0-alpine
FROM python:2.7.14-alpine3.7

# Set Workdir and copy the code
WORKDIR /app
COPY . /app

# Install dependencies
RUN apk add --no-cache --virtual .build-depends gcc musl-dev && \
    pip install -r /app/requirements.txt && \
    apk del .build-depends

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

CMD ["python", "post_app.py"]
