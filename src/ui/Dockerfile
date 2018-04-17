# UI service Dockerfile

FROM alpine:3.7

# Install build environment and Ruby base packages && Clear apk cache
RUN apk update --no-cache && \
    apk add --no-cache --virtual .build-depends ruby-dev gcc make libc-dev g++ && \
    apk add --no-cache ruby ruby-bundler

# Create and set Workdir
ENV APP_HOME /app
RUN mkdir $"APP_HOME"
WORKDIR $APP_HOME

# Copy App code and install dependencies
COPY . $APP_HOME/
RUN bundle install && \
    apk del .build-depends

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
