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

			_, bc := helper.RequestPOST("/save", "100500", expected, 0)
			bc()
		})
	})

	Context("get article #2", func() {
		It("article getting", func() {
			b, bc := helper.RequestGET("/article/2", "100500", 200)
			bc()

			actual := Article{}

			err := json.Unmarshal(b, &actual)
			Expect(err).NotTo(HaveOccurred())

			Expect(expected.Title).To(Equal(actual.Title))
		})
	})

	Context("not exists article", func() {
		It("getting 404", func() {
			_, bc := helper.RequestGET("/article/3", "100500", 404)
			bc()
		})
	})

	XContext("create article 1M", func() {
		It("article added", func() {
			var a Article

			for i := 0; i < 1000000; i++ {
				a = Article{
					CategoryID: int64(helper.RandIntRange(1, 1000)),
					CreateAt:   time.Now().Format("2006-01-02 15:04:05"),
					UpdateAt:   time.Now().Format("2006-01-02 15:04:05"),
					Title:      helper.RandStringRange(1, 250),
					Body:       helper.RandStringRange(1, 1000),
					Tags: []string{
						helper.RandStringRange(1, 10),
						helper.RandStringRange(1, 10),
						helper.RandStringRange(1, 10),
					},
					Seo: Seo{
						Title:       helper.RandStringRange(1, 500),
						Description: helper.RandStringRange(1, 500),
						Keywords: []string{
							helper.RandStringRange(1, 10),
							helper.RandStringRange(1, 10),
							helper.RandStringRange(1, 10),
						},
					},
					IsVisible: true,
					IsDelete:  false,
				}

				_, bc := helper.RequestPOST("/save", "100", a, i)
				bc()
			}
		})
	})
})
