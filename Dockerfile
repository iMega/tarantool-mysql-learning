FROM tarantool/tarantool as builder

RUN apk add --upd alpine-sdk cmake openssl-dev curl git wget && \
    luarocks install inspect && \
    tarantoolctl rocks install mysql
# /usr/local/share/lua/5.1/inspect.lua
#-- Installing: /opt/tarantool/.rocks/share/tarantool/rocks/mysql/scm-1/lib/mysql/driver.so
#-- Installing: /opt/tarantool/.rocks/share/tarantool/rocks/mysql/scm-1/lua/mysql/init.lua

FROM tarantool/tarantool
EXPOSE 3301
WORKDIR /opt/tarantool
RUN mkdir -p src /opt/tarantool/.rocks/share/tarantool/rocks/mysql

COPY src src/
RUN ls -la
COPY --from=builder /usr/local/share/lua/5.1/inspect.lua /usr/local/share/lua/5.1/inspect.lua
COPY --from=builder /opt/tarantool/.rocks/share/tarantool/rocks/mysql /opt/tarantool/.rocks/share/tarantool/rocks/mysql

CMD ["tarantool", "src/init.lua"]
