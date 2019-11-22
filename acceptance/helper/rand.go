package helper

import (
	"math/rand"
	"time"
)

const charset = "abcdefghijklmnopqrstuvwxyz" +
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var seededRand *rand.Rand = rand.New(
	rand.NewSource(time.Now().UnixNano()))

func StringWithCharset(length int, charset string) string {
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}

func RandStringRange(min, max int) string {
	length := seededRand.Intn(max-min+1) + min
	return StringWithCharset(length, charset)
}

func RandIntRange(min, max int) int {
	return seededRand.Intn(max-min+1) + min
}
