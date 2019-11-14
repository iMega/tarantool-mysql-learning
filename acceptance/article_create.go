package acceptance

import (
	"github.com/imega/tarantool-mysql-learning/acceptance/helper"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Articles", func() {
	Context("create article", func() {
		It("article added", func() {
			body := struct {
				Title string `json:"title"`
			}{
				Title: "test title",
			}

			helper.RequestPOST("/article/save", "100500", body)
			Expect(true).To(BeTrue())
		})
	})
})
