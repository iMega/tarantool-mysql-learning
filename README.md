### Build

```
docker-compose build app
```

### Test sigterm

1 terminal

```
docker-compose rm -fv app && docker-compose up app
```

2 terminal

```
 while :; do curl -o /dev/null -s -w "%{http_code}\n" localhost:9000; sleep 0.5; done
```

3 terminal

```
docker-compose stop -t 15 app
```
