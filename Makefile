REPO = github.com/imega/tarantool-mysql-learning
CWD = /go/src/$(REPO)

GO_IMG_DEV = golang:1.10-alpine3.8

clean:
	@-rm $(CURDIR)/mysql.log
	@-rm $(CURDIR)/mysql-error.log
	@GO_IMG_DEV=$(GO_IMG_DEV) docker-compose rm -sfv

acceptance:
	@touch $(CURDIR)/mysql.log
	@chmod 666 $(CURDIR)/mysql.log
	@touch $(CURDIR)/mysql-error.log
	@chmod 666 $(CURDIR)/mysql-error.log
	@GO_IMG_DEV=$(GO_IMG_DEV) docker-compose up -d --scale acceptance=0
	@GO_IMG_DEV=$(GO_IMG_DEV) docker-compose up --abort-on-container-exit acceptance

lint:
	@docker run --rm -v $(CURDIR):/data yangm97/luacheck

test: lint clean acceptance

testworker:
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"===","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"====","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"=====","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"======","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"=======","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"========","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"=========","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}' && \
	curl -XPOST nh:9000/save -H 'X-Req-Id: 1' -H 'X-Site-Id: 100' -d '{"category_id":0,"create_at":"2019-11-22 05:52:04","update_at":"2019-11-18 11:24:00","title":"==========","body":"1","tags":[],"seo":{"title":"","description":"qqqqqqqqqq"},"is_visible":true,"is_deleted":false}'

validate:
	siege --concurrent=200 --reps=200 --file=links.txt --log=siege.log --header='X-Req-Id: 1' --header='X-Site-Id: 100' --verbose | grep HTTP | awk '{ if ($5-200 == substr($9,10)*1) print $5-200,substr($9,10),"="; else print $5-200,substr($9,10),"<>"; }' | grep = | wc -l

.PHONY: acceptance

