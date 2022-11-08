FROM elixir:1.14
COPY . .
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile
EXPOSE 4000
CMD ["mix", "phx.server"]