# Dockerfile for Mayday-2.0 Rails project

FROM ruby:2.2.4-onbuild

MAINTAINER andrew.tork.baker@gmail.com

CMD ["./bin/rails", "server"]
