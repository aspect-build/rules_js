package gazelle

import (
	godsutils "github.com/emirpasic/gods/utils"
)

// ImportStatement represents a path imported from a source file.
// Imports can be of any form (es6, cjs, amd, ...).
// Imports may be relative ot the source, absolute, workspace, named modules etc.
type ImportStatement struct {
	// The TypeScript path as seen on import statements.
	Path string `json:"path"`
	// The path of the file containing the import
	SourcePath string `json:"sourcepath"`
}

// importStatementComparator compares modules by name.
func importStatementComparator(a, b interface{}) int {
	return godsutils.StringComparator(a.(ImportStatement).Path, b.(ImportStatement).Path)
}
