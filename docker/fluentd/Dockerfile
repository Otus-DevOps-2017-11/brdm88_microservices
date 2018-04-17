FROM fluent/fluentd:v0.12
RUN gem install fluent-plugin-elasticsearch --no-rodc --no-ri --version 1.9.5
RUN gem install fluent-plugin-grok-parser --no-rodc --no-ri --version 1.0.0
COPY fluent.conf /fluentd/etc
