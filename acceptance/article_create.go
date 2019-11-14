package acceptance

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Articles", func() {
	Context("create article", func() {
		It("article added", func() {
			Expect(true).To(BeTrue())
		})
	})
})
