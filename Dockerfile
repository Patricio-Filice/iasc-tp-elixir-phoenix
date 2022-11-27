FROM elixir:1.14

COPY . .

RUN mix local.hex --force && mix local.rebar --force
RUN mix do deps.get, deps.compile

EXPOSE 4000

ARG NODE_NAME
ARG COOKIE_VALUE
ARG PORT

CMD PORT=${PORT} elixir --sname ${NODE_NAME} --cookie ${COOKIE_VALUE} -S mix phx.server