FROM alpine:3.8

RUN apk --no-cache add \
  ruby-bundler \
  diffutils # this is required for diffy to work on alpine

RUN gem install --no-document --no-ri terraform_landscape
CMD ['landscape']
