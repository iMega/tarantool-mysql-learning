IMG = alpinemariadb

build:
	docker run --rm -t -v $(CURDIR)/main.c:/test/main.c -w /test \
	--network tarantool-mysql-learning_default $(IMG) \
	sh -c ' \
		gcc -o mysqltest main.c $$(mysql_config --libs) && \
		./mysqltest \
	'

image:
	@docker build -t $(IMG) .

