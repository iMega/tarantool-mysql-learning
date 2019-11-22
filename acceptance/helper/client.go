package helper

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httputil"

	. "github.com/onsi/gomega"
)

const defaultStyle = "\x1b[0m"
const cyanColor = "\x1b[36m"
const yellowColor = "\x1b[33m"

var (
	APIURL = "http://app:9000"

	dumpReq = func(req *http.Request) {
		dump, err := httputil.DumpRequestOut(req, true)
		Expect(err).To(BeNil())
		fmt.Printf("%s\nREQUEST:\n%s\n%s\n", cyanColor, string(dump), defaultStyle)
	}

	dumpRes = func(res *http.Response) {
		dump, err := httputil.DumpResponse(res, true)
		Expect(err).To(BeNil())
		fmt.Printf("%s\nRESPONSE:\n%s\n%s\n", yellowColor, string(dump), defaultStyle)
	}
)

func RequestPOST(uri, site string, b interface{}, i int) ([]byte, func()) {
	ret, err := json.Marshal(b)
	Expect(err).NotTo(HaveOccurred())

	req, err := http.NewRequest(http.MethodPost, APIURL+uri, bytes.NewBuffer(ret))
	req.Header.Set("X-SITE-ID", site)
	req.Header.Set("X-REQ-ID", "efccc287-87c2-4bcb-aec2-6cbc987bd8fd")

	// dumpReq(req)

	res, err := http.DefaultClient.Do(req)
	Expect(err).NotTo(HaveOccurred())
	Expect(res.StatusCode).To(Equal(http.StatusOK), "Records: %d", i-1)

	// dumpRes(res)

	body, err := ioutil.ReadAll(res.Body)
	Expect(err).NotTo(HaveOccurred())

	var bodyClose = func() {
		res.Body.Close()
	}

	return body, bodyClose
}

func RequestGET(uri, site string) ([]byte, func()) {
	req, err := http.NewRequest(http.MethodGet, APIURL+uri, nil)
	req.Header.Set("X-SITE-ID", site)
	req.Header.Set("X-REQ-ID", "efccc287-87c2-4bcb-aec2-6cbc987bd8fd")

	dumpReq(req)

	res, err := http.DefaultClient.Do(req)
	Expect(err).NotTo(HaveOccurred())
	Expect(res.StatusCode).To(Equal(http.StatusOK))

	dumpRes(res)

	body, err := ioutil.ReadAll(res.Body)
	Expect(err).NotTo(HaveOccurred())

	var bodyClose = func() {
		res.Body.Close()
	}

	return body, bodyClose
}
