package gazelle

import (
	"testing"

	"github.com/bazelbuild/rules_go/go/tools/bazel"
)

func createTsConfigOptions(t *testing.T, configPath string) *TypeScriptConfig {
	runfile, err := bazel.Runfile("gazelle/ts_test/" + configPath)
	if err != nil {
		t.Fatalf("cannot lookup runfile: %v", err)
	}

	cf := NewTypeScriptConfig("root")
	cf.SetTsconfigJSON(runfile)
	return cf
}

func TestConfig(t *testing.T) {

	t.Run("IsWithinTsRoot empty config", func(t *testing.T) {
		cf := createTsConfigOptions(t, "empty.json")

		inRoot := []string{".", "./", "src", "./src", "./src/a"}

		for _, p := range inRoot {
			if !cf.IsWithinTsRoot(p) {
				t.Errorf("IsWithinTsRoot(%s): %s\n", ".", p)
			}
		}
	})

	t.Run("IsWithinTsRoot subdir config", func(t *testing.T) {
		cf := createTsConfigOptions(t, "rootdir_src.json")

		inRoot := []string{"src", "./src", "./src/a"}
		outRoot := []string{".", "./", "non", "./non", "non/src", "./non/src"}

		for _, p := range inRoot {
			if !cf.IsWithinTsRoot(p) {
				t.Errorf("IsWithinTsRoot(%s): %s\n", "src", p)
			}
		}

		for _, p := range outRoot {
			if cf.IsWithinTsRoot(p) {
				t.Errorf("NOT IsWithinTsRoot(%s): %s\n", "src", p)
			}
		}
	})

}
