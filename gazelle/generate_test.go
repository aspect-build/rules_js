package gazelle

import (
	"fmt"
	"reflect"
	"testing"
)

func TestGenerate(t *testing.T) {
	for _, tc := range []struct {
		pkg, from, impt string
		expected        string
	}{
		// Simple
		{
			pkg:      "",
			from:     "from.ts",
			impt:     "./empty",
			expected: "empty",
		},
		{
			pkg:      "",
			from:     "from/sub.ts",
			impt:     "./empty",
			expected: "from/empty",
		},
		{
			pkg:      "foo",
			from:     "from.ts",
			impt:     "./bar",
			expected: "foo/bar",
		},
		{
			pkg:      "foo",
			from:     "from/sub.ts",
			impt:     "./bar",
			expected: "foo/from/bar",
		},
		// Absolute
		{
			pkg:      "",
			from:     "from.ts",
			impt:     "workspace/is/common",
			expected: "workspace/is/common",
		},
		{
			pkg:      "dont-use-me",
			from:     "from.ts",
			impt:     "workspace/is/common",
			expected: "workspace/is/common",
		},
		// Parent (..)
		{
			pkg:      "",
			from:     "from.ts",
			impt:     "./foo/../bar",
			expected: "bar",
		},
		{
			pkg:      "",
			from:     "from/sub.ts",
			impt:     "./foo/../bar",
			expected: "from/bar",
		},
		{
			pkg:      "foo",
			from:     "from.ts",
			impt:     "../bar",
			expected: "bar",
		},
		{
			pkg:      "foo",
			from:     "from/sub.ts",
			impt:     "../bar",
			expected: "foo/bar",
		},
		{
			pkg:      "foo",
			from:     "from.ts",
			impt:     "./baz/../bar",
			expected: "foo/bar",
		},
		{
			pkg:      "foo",
			from:     "from/sub.ts",
			impt:     "./baz/../bar",
			expected: "foo/from/bar",
		},
		// Absolute parent
		{
			pkg:      "dont-use-me",
			from:     "from.ts",
			impt:     "baz/../bar",
			expected: "bar",
		},
		{
			pkg:      "dont-use-me",
			from:     "from/sub.ts",
			impt:     "baz/../bar",
			expected: "bar",
		},
	} {
		desc := fmt.Sprintf("toWorkspacePath(%s, %s, %s)", tc.pkg, tc.from, tc.impt)

		t.Run(desc, func(t *testing.T) {
			importPath := toWorkspacePath(tc.pkg, tc.from, tc.impt)

			if !reflect.DeepEqual(importPath, tc.expected) {
				t.Errorf("toWorkspacePath('%s', '%s', '%s'): \nactual:   %s\nexpected:  %s\n", tc.pkg, tc.from, tc.impt, importPath, tc.expected)
			}
		})
	}
}
