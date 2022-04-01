package gazelle

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"

	"github.com/bazelbuild/rules_go/go/tools/bazel"
	"github.com/emirpasic/gods/sets/treeset"
)

var nativeModules *treeset.Set

const STD_MODULES_BINARY = "node_std_modules"
const STD_MODULES_BINARY_EXECUTABLE_FORMAT = "gazelle/_" + STD_MODULES_BINARY + "_launcher.sh"

func isNodeImport(imprt string) bool {
	// TODO(jbedard): lock
	if nativeModules == nil {
		nativeModules = fetchNativeNodeModules()
	}
	return nativeModules.Contains(imprt)
}

func fetchNativeNodeModules() *treeset.Set {
	moduleListRunfile, bazelError := bazel.Runfile(STD_MODULES_BINARY_EXECUTABLE_FORMAT)
	if bazelError != nil {
		fmt.Printf("Failed to initialize %s: %v\n", STD_MODULES_BINARY, bazelError)
		os.Exit(1)
	}

	moduleListCmd := exec.Command(moduleListRunfile)

	jsonModules, nodeError := moduleListCmd.Output()
	if nodeError != nil {
		fmt.Printf("Failed to launch node builtinModules: %s\n", nodeError)
		os.Exit(1)
	}

	modules := []string{}

	parseError := json.Unmarshal(jsonModules, &modules)
	if parseError != nil {
		fmt.Printf("Failed to parse node builtinModules: %s\n", parseError)
		os.Exit(1)
	}

	set := treeset.NewWithStringComparator()
	for _, module := range modules {
		set.Add(module)
	}
	return set
}
