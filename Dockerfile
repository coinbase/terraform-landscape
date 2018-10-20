FROM alpine:3.8

RUN apk --no-cache add \
  ruby-bundler=1.16.2-r1 \
  ruby-json=2.5.2-r0 \
  diffutils=3.6-r1 # this is required for diffy to work on alpine

RUN gem install --no-document --no-ri terraform_landscape
ENTRYPOINT ["landscape"]
