package acceptance_test

import (
	"errors"
	"log"
	"net/http"
	"testing"
	"time"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = BeforeSuite(func() {
	err := WaitForSystemUnderTestReady()
	Expect(err).NotTo(HaveOccurred())
})

func WaitForSystemUnderTestReady() error {
	attempts := 30
	for {
		resp, err := http.Get("http://app:9000")
		if err == nil && resp.StatusCode == http.StatusOK {
			break
		}
		log.Printf("ATTEMPTING TO CONNECT %d", attempts)
		attempts -= 1
		if attempts == 0 {
			return errors.New("SUT is not ready for tests")
		}
		<-time.After(time.Duration(2 * time.Second))
	}

	return nil
}

func TestAcceptance(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Acceptance Suite")
}
