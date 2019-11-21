package acceptance

import (
	"encoding/json"
	"time"

	"github.com/imega/tarantool-mysql-learning/acceptance/helper"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

type Seo struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Keywords    []string `json:"keywords"`
}

type Article struct {
	CategoryID int64    `json:"category_id"`
	CreateAt   string   `json:"create_at"`
	UpdateAt   string   `json:"update_at"`
	Title      string   `json:"title"`
	Body       string   `json:"body"`
	Tags       []string `json:"tags"`
	Seo        Seo      `json:"seo"`
	IsVisible  bool     `json:"is_visible"`
	IsDelete   bool     `json:"is_deleted"`
}

var _ = Describe("Articles", func() {
	var expected Article
	Context("create article", func() {
		It("article added", func() {
			expected = Article{
				CategoryID: 0,
				CreateAt:   time.Now().Format("2006-01-02 15:04:05"),
				UpdateAt:   time.Now().Format("2006-01-02 15:04:05"),
				Title:      "test title",
				Body:       "body",
				Tags:       []string{"tag1", "tag2", "tag3"},
				Seo: Seo{
					Title:       "seo-title",
					Description: "seo-desc",
					Keywords:    []string{"key"},
				},
				IsVisible: true,
				IsDelete:  false,
			}

			_, bc := helper.RequestPOST("/save", "100500", expected)
			bc()
		})
	})

	Context("get article #1", func() {
		It("article geting", func() {
			b, bc := helper.RequestGET("/article/2", "100500")
			bc()

			actual := Article{}

			err := json.Unmarshal(b, &actual)
			Expect(err).NotTo(HaveOccurred())

			Expect(expected.Title).To(Equal(actual.Title))
		})
	})
})
