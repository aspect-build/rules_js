package gazelle

import (
	"flag"
	"fmt"
	"log"
	"strconv"
	"strings"

	"github.com/bazelbuild/bazel-gazelle/config"
	"github.com/bazelbuild/bazel-gazelle/rule"
)

// Configurer satisfies the config.Configurer interface. It's the
// language-specific configuration extension.
type Configurer struct{}

// RegisterFlags registers command-line flags used by the extension. This
// method is called once with the root configuration when Gazelle
// starts. RegisterFlags may set an initial values in Config.Exts. When flags
// are set, they should modify these values.
func (ts *Configurer) RegisterFlags(fs *flag.FlagSet, cmd string, c *config.Config) {}

// CheckFlags validates the configuration after command line flags are parsed.
// This is called once with the root configuration when Gazelle starts.
// CheckFlags may set default values in flags or make implied changes.
func (ts *Configurer) CheckFlags(fs *flag.FlagSet, c *config.Config) error {
	return nil
}

// KnownDirectives returns a list of directive keys that this Configurer can
// interpret. Gazelle prints errors for directives that are not recoginized by
// any Configurer.
func (ts *Configurer) KnownDirectives() []string {
	return []string{
		TypeScriptExtensionDirective,
		IgnoreImportsDirective,
		ValidateImportStatementsDirective,
		EnvironmentDirective,
		LibraryNamingConvention,
		TestsNamingConvention,
		SourcesFileGlob,
		TestsFileGlob,
		NpmPackageJson,
		NpmWorkspace,
	}
}

// Configure modifies the configuration using directives and other information
// extracted from a build file. Configure is called in each directory.
//
// c is the configuration for the current directory. It starts out as a copy
// of the configuration for the parent directory.
//
// rel is the slash-separated relative path from the repository root to
// the current directory. It is "" for the root directory itself.
//
// f is the build file for the current directory or nil if there is no
// existing build file.
func (ts *Configurer) Configure(c *config.Config, rel string, f *rule.File) {
	// Create the root config.
	if _, exists := c.Exts[languageName]; !exists {
		rootConfig := NewTypeScriptConfig(c.RepoRoot)
		c.Exts[languageName] = Configs{"": rootConfig}
	}

	configs := c.Exts[languageName].(Configs)

	config, exists := configs[rel]
	if !exists {
		parent := configs.ParentForPackage(rel)
		config = parent.NewChild()
		configs[rel] = config
	}

	if f == nil {
		return
	}

	for _, d := range f.Directives {
		value := strings.TrimSpace(d.Value)

		switch d.Key {
		case "exclude":
			// We record the exclude directive since we do manual tree traversal of subdirs.
			config.AddExcludedPattern(value)
		case TypeScriptExtensionDirective:
			switch d.Value {
			case "enabled":
				config.SetGenerationEnabled(true)
			case "disabled":
				config.SetGenerationEnabled(false)
			default:
				err := fmt.Errorf("invalid value for directive %q: %s: possible values are enabled/disabled",
					TypeScriptExtensionDirective, d.Value)
				log.Fatal(err)
			}
		case IgnoreImportsDirective:
			for _, ignoreDependency := range strings.Split(d.Value, ",") {
				config.AddIgnoredImport(strings.TrimSpace(ignoreDependency))
			}
		case ValidateImportStatementsDirective:
			v, err := strconv.ParseBool(value)
			if err != nil {
				log.Fatal(err)
			}
			config.SetValidateImportStatements(v)
		case EnvironmentDirective:
			config.SetEnvironmentType(EnvironmentType(value))
		case LibraryNamingConvention:
			config.SetLibraryNamingConvention(value)
		case TestsNamingConvention:
			config.SetTestsNamingLibraryConvention(value)
		case SourcesFileGlob:
			config.SetSourceFileGlob(value)
		case TestsFileGlob:
			config.SetTestFileGlob(value)
		case NpmWorkspace:
			config.SetNpmWorkspace(value)
		case NpmPackageJson:
			config.SetNpmPackageJSON(value)
		}
	}
}
