FROM tarantool/tarantool:2.2.1 as builder

RUN apk add --upd alpine-sdk cmake openssl-dev curl git wget unzip && \
    luarocks install inspect && \
    tarantoolctl rocks install mysql

FROM tarantool/tarantool:2.2.1
EXPOSE 3301
WORKDIR /opt/tarantool

ENV LUAROCK_HTTP_VERSION=2.0.1

RUN apk add --upd alpine-sdk cmake openssl-dev curl git wget lua5.1-dev unzip && \
    luarocks install luaposix && \
    luarocks remove http && \
    luarocks install http ${LUAROCK_HTTP_VERSION}
RUN mkdir -p /opt/.rocks/share/tarantool/rocks/mysql

COPY src .
COPY --from=builder /usr/local/share/lua/5.1/inspect.lua /usr/local/share/lua/5.1/inspect.lua
COPY --from=builder /opt/tarantool/.rocks/share/tarantool/rocks/mysql /opt/.rocks/share/tarantool/rocks/mysql

# STOPSIGNAL SIGQUIT
# STOPSIGNAL SIGINT
# STOPSIGNAL SIGTERM

CMD ["tarantool", "init.lua"]
