FROM elixir:1.14

COPY . .

RUN mix local.hex --force && mix local.rebar --force
RUN mix do deps.get, deps.compile

EXPOSE 4000

CMD ["mix", "phx.server"]