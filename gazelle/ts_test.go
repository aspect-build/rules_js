package gazelle

import (
	"testing"

	"github.com/bazelbuild/rules_go/go/tools/bazel"
)

func parseTest(t *testing.T, configPath string) *TsCompilerOptions {
	testDataDir, err := bazel.Runfile("gazelle/ts_test/")
	if err != nil {
		t.Fatalf("cannot lookup runfile: %v", err)
	}

	options, err := ParseTsConfigOptions(testDataDir, configPath)
	if err != nil {
		t.Fatalf("failed to parse options: %v", err)
	}

	return options
}

func TestTypescriptApi(t *testing.T) {

	t.Run("parse a basic tsconfig baseurl", func(t *testing.T) {
		options := parseTest(t, "baseurl_simple.json")

		if options.BaseUrl != "src" {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.BaseUrl, "src")
		}

		if options.RootDir != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.RootDir, ".")
		}
	})

	t.Run("parse a tsconfig with no config", func(t *testing.T) {
		options := parseTest(t, "empty.json")

		if options.BaseUrl != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.BaseUrl, ".")
		}

		if options.RootDir != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.RootDir, ".")
		}
	})

	t.Run("parse a tsconfig with no compilerOptions", func(t *testing.T) {
		options := parseTest(t, "empty_compileroptions.json")

		if options.BaseUrl != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.BaseUrl, ".")
		}

		if options.RootDir != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.RootDir, ".")
		}
	})

	t.Run("parse a tsconfig with rootDir", func(t *testing.T) {
		options := parseTest(t, "rootdir_src.json")

		if options.BaseUrl != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.BaseUrl, ".")
		}

		if options.RootDir != "src" {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.RootDir, "src")
		}
	})

	t.Run("parse a tsconfig with rootDir relative", func(t *testing.T) {
		options := parseTest(t, "rootdir_dotsrc.json")

		if options.BaseUrl != "." {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.BaseUrl, ".")
		}

		if options.RootDir != "src" {
			t.Errorf("ParseTsConfigOptions: RootDir\nactual:   %s\nexpected:  %s\n", options.RootDir, "src")
		}
	})

}
