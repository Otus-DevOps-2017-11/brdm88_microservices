# Comment service Dockerfile

FROM alpine:3.7

# Install build environment and Ruby base packages && Clear apk cache
RUN apk update --no-cache && \
    apk add --no-cache --virtual .build-depends ruby-dev ruby-bundler gcc make libc-dev && \
    apk add --no-cache ruby ruby-json

# Create and set Workdir
ENV APP_HOME /app
RUN mkdir $"APP_HOME"
WORKDIR $APP_HOME

# Copy App code and install dependencies
COPY . $APP_HOME/
RUN bundle install && \
    apk del .build-depends

# Set environment variables and startup command
ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
