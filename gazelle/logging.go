package gazelle

import "fmt"

const (
	DEBUG_ENABLED = false
)

func DEBUG(str string, args ...interface{}) {
	if DEBUG_ENABLED {
		fmt.Printf(str+"\n", args...)
	}
}
