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
 while :; do curl -o /dev/null -s -w "%{http_code}\n" app:9000; sleep 0.5; done
```

3 terminal

```
docker-compose stop -t 15 app
```

## CRASH

```
tmlapp        | Segmentation fault
tmlapp        |   code: SEGV_MAPERR
tmlapp        |   addr: 0
tmlapp        |   context: 0x7f8cb387f6c0
tmlapp        |   siginfo: 0x7f8cb387f7f0
tmlapp        |   rax      0x0                0
tmlapp        |   rbx      0x5601c2a2c2f8     94565560402680
tmlapp        |   rcx      0x0                0
tmlapp        |   rdx      0x3                3
tmlapp        |   rsi      0x5601c2a07063     94565560250467
tmlapp        |   rdi      0x0                0
tmlapp        |   rsp      0x7f8cb387fd78     140242284182904
tmlapp        |   rbp      0x3                3
tmlapp        |   r8       0x1                1
tmlapp        |   r9       0x0                0
tmlapp        |   r10      0x40dcb718         1088206616
tmlapp        |   r11      0x9                9
tmlapp        |   r12      0x3                3
tmlapp        |   r13      0x5601c2a2a600     94565560395264
tmlapp        |   r14      0x0                0
tmlapp        |   r15      0x5601c2a07061     94565560250465
tmlapp        |   rip      0x7f8d1ba4b0a0     140244030894240
tmlapp        |   eflags   0x10206            66054
tmlapp        |   cs       0x33               51
tmlapp        |   gs       0x0                0
tmlapp        |   fs       0x0                0
tmlapp        |   cr2      0x0                0
tmlapp        |   err      0x6                6
tmlapp        |   oldmask  0x0                0
tmlapp        |   trapno   0xe                14
tmlapp        | Current time: 1574495001
tmlapp        | Please file a bug at http://github.com/tarantool/tarantool/issues
tmlapp        | Attempting backtrace... Note: since the server has already crashed,
tmlapp        | this may fail as well
tmlapp        | #0  0x5601c1c7d219 in print_backtrace+9
tmlapp        | #1  0x5601c1b68dda in _ZL12sig_fatal_cbiP9siginfo_tPv+ca
tmlapp        | #2  0x7f8d1ba40e17 in sigwaitinfo+8
```

Reproduce case:

```
tarantool> mysql = require("mysql")
---
...
tarantool> pool = mysql.pool_create({host = 'dbstorage',port = 3360,user = 'root',password = 'qwerty',db = 'tester',size = 5})
---
...
tarantool> conn = pool:get()
---
...
tarantool> conn:execute("select `f_longtext` from mytable where pri = ?", 1)
---
- error: null
...
tarantool> conn:execute("select `f_longblob` from mytable where pri = ?", 1)
---
- error: null
...
tarantool> conn:execute("select `f_longtext_null` from mytable where pri = ?", 2)
---
- error: null
...
tarantool> conn:execute("select `f_longblob_null` from mytable where pri = ?", 2)
---
- error: null
...
```
