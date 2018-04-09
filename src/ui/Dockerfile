# UI service Dockerfile

FROM alpine:3.7

# Install build environment and Ruby base packages && Clear apk cache
RUN apk update \
&& apk add ruby-dev gcc make libc-dev g++ \
&& apk add ruby ruby-bundler \
&& rm -rf /var/cache/apk/*

# Create and set Workdir
ENV APP_HOME /app
RUN mkdir $"APP_HOME"
WORKDIR $APP_HOME

# Copy App code and install dependencies
COPY . $APP_HOME/
RUN bundle install

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
