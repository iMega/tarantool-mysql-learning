REPO = github.com/imega/tarantool-mysql-learning
CWD = /go/src/$(REPO)

GO_IMG_DEV = golang:1.10-alpine3.8

clean:
	@-rm $(CURDIR)/mysql.log
	@GO_IMG_DEV=$(GO_IMG_DEV) docker-compose rm -sfv

acceptance:
	@touch $(CURDIR)/mysql.log
	@chmod 666 $(CURDIR)/mysql.log
	@GO_IMG_DEV=$(GO_IMG_DEV) docker-compose up -d --scale acceptance=0
	@-GO_IMG_DEV=$(GO_IMG_DEV) docker-compose up --abort-on-container-exit acceptance
	@docker-compose ps
	@cat $(CURDIR)/mysql.log

lint:
	@docker run --rm -v $(CURDIR):/data yangm97/luacheck

test: lint clean acceptance

.PHONY: acceptance

