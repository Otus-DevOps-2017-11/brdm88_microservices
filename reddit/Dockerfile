# Reddit Monolith app build script - multi-stage build strategy

## Build stage
FROM alpine:3.7 as gem-build

# Install build environment and Ruby base packages && Clear apk cache
RUN apk update --no-cache \
&& apk add --no-cache ruby-dev gcc make libc-dev ruby ruby-bundler

# Create and set Workdir
ENV BUILD_HOME /tmp/gembuild
RUN mkdir $"BUILD_HOME"
WORKDIR $BUILD_HOME

COPY Gemfile* $BUILD_HOME
RUN bundle install


## Prod run stage
FROM alpine:3.7

# Install Ruby base packages && Clear apk cache
RUN apk update --no-cache \
&& apk add --no-cache ruby ruby-json

# Create and set Workdir
ENV APP_HOME /app
WORKDIR $APP_HOME
RUN mkdir $"APP_HOME"


# Copy App code and previously built dependencies
COPY . $APP_HOME/
COPY --from=gem-build /tmp/gembuild/ruby/*/bin/* /usr/local/bin
COPY --from=gem-build /tmp/gembuild/ruby /usr/lib/ruby/gems/

CMD ["puma"]
