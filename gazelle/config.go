package gazelle

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/bmatcuk/doublestar"
	"github.com/emirpasic/gods/sets/treeset"
)

type EnvironmentType string

const (
	EnvironmentNode    EnvironmentType = "node"
	EnvironmentBrowser EnvironmentType = "browser"
	EnvironmentOther   EnvironmentType = "other"
)

// Directives
const (
	// TypeScriptExtensionDirective represents the directive that controls whether
	// this TypeScript generation is enabled or not. Sub-packages inherit this value.
	// Can be either "enabled" or "disabled". Defaults to "enabled".
	TypeScriptExtensionDirective = "typescript_extension"
	// IgnoreImportsDirective represents the directive that controls the
	// ignored dependencies from the generated targets.
	IgnoreImportsDirective = "ts_ignore_imports"
	// ValidateImportStatementsDirective represents the directive that controls
	// whether the TypeScript import statements should be validated.
	ValidateImportStatementsDirective = "ts_validate_import_statements"
	// EnvironmentDirective represents the runtime environment such as in a browser, node etc.
	// and effects which native imports are available.
	EnvironmentDirective = "ts_environment"
	// The package.json containing third-party dependencies.
	NpmPackageJson = "ts_npm_package_json"
	// The bazel workspace name for the NpmPackage
	NpmWorkspace = "ts_npm_package_workspace"
	// LibraryNamingConvention represents the directive that controls the
	// ts_project naming convention. It interpolates $package_name$ with the
	// Bazel package name. E.g. if the Bazel package name is `foo`, setting this
	// to `$package_name$_my_lib` would render to `foo_my_lib`.
	LibraryNamingConvention = "ts_project_naming_convention"
	// TestsNamingConvention represents the directive that controls the ts_project test
	// naming convention. See ts_project_naming_convention for more info on
	// the package name interpolation.
	TestsNamingConvention = "ts_tests_naming_convention"
	// The glob for source files, excludes files matching TestsFileGlob
	SourcesFileGlob = "ts_srcs_file_glob"
	// The glob for test files
	TestsFileGlob = "ts_tests_file_glob"
)

const (
	packageNameNamingConventionSubstitution = "$package_name$"
)

var (
	// BUILD file names
	buildFileNames = []string{"BUILD", "BUILD.bazel"}

	// Set of supported source file extensions
	sourceFileExtensions = treeset.NewWithStringComparator("js", "mjs", "ts", "tsx", "jsx")

	// Array of sourceFileExtensions
	sourceFileExtensionsArray = []string{"js", "mjs", "ts", "tsx", "jsx"}

	// Supported data file extensions that typescript can reference
	dataFileExtensions = treeset.NewWithStringComparator("json")
)

// Configs is an extension of map[string]*TypeScriptConfig. It provides finding methods
// on top of the mapping.
type Configs map[string]*TypeScriptConfig

// ParentForPackage returns the parent TypeScriptConfig for the given Bazel package.
func (c *Configs) ParentForPackage(pkg string) *TypeScriptConfig {
	dir := filepath.Dir(pkg)
	if dir == "." {
		dir = ""
	}
	parent := (map[string]*TypeScriptConfig)(*c)[dir]
	return parent
}

// TypeScriptConfig represents a config extension for a specific Bazel package.
type TypeScriptConfig struct {
	parent *TypeScriptConfig

	generationEnabled bool
	repoRoot          string
	npm_package_json  string
	npm_workspace     string
	environmentType   EnvironmentType

	excludedPatterns         *treeset.Set
	ignoreDependencies       *treeset.Set
	validateImportStatements bool
	libraryNamingConvention  string
	testsNamingConvention    string
	srcsFileGlob             string
	testsFileGlob            string

	_npm_packages *treeset.Set
}

// New creates a new TypeScriptConfig.
func NewTypeScriptConfig(
	repoRoot string,
) *TypeScriptConfig {
	return &TypeScriptConfig{
		generationEnabled:        true,
		repoRoot:                 repoRoot,
		environmentType:          EnvironmentOther,
		npm_package_json:         "package.json",
		npm_workspace:            "npm",
		excludedPatterns:         treeset.NewWithStringComparator(),
		ignoreDependencies:       treeset.NewWithStringComparator(),
		validateImportStatements: true,
		libraryNamingConvention:  packageNameNamingConventionSubstitution,
		testsNamingConvention:    fmt.Sprintf("%s_tests", packageNameNamingConventionSubstitution),
		srcsFileGlob:             fmt.Sprintf("**/*.{%s}", strings.Join(sourceFileExtensionsArray, ",")),
		testsFileGlob:            fmt.Sprintf("**/*.{spec,test}.{%s}", strings.Join(sourceFileExtensionsArray, ",")),

		_npm_packages: nil,
	}
}

// Parent returns the parent config.
func (c *TypeScriptConfig) Parent() *TypeScriptConfig {
	return c.parent
}

// NewChild creates a new child TypeScriptConfig. It inherits desired values from the
// current TypeScriptConfig and sets itself as the parent to the child.
func (c *TypeScriptConfig) NewChild() *TypeScriptConfig {
	return &TypeScriptConfig{
		parent:                   c,
		generationEnabled:        c.generationEnabled,
		repoRoot:                 c.repoRoot,
		environmentType:          c.environmentType,
		npm_package_json:         c.npm_package_json,
		npm_workspace:            c.npm_workspace,
		excludedPatterns:         c.excludedPatterns,
		ignoreDependencies:       treeset.NewWithStringComparator(),
		validateImportStatements: c.validateImportStatements,
		libraryNamingConvention:  c.libraryNamingConvention,
		srcsFileGlob:             c.srcsFileGlob,
		testsNamingConvention:    c.testsNamingConvention,
		testsFileGlob:            c.testsFileGlob,

		_npm_packages: c._npm_packages,
	}
}

// AddExcludedPattern adds a glob pattern parsed from the standard
// gazelle:exclude directive.
func (c *TypeScriptConfig) AddExcludedPattern(pattern string) {
	c.excludedPatterns.Add(pattern)
}

// ExcludedPatterns returns the excluded patterns list.
func (c *TypeScriptConfig) IsFileExcluded(filePath string) bool {
	excludeIt := c.excludedPatterns.Iterator()
	for excludeIt.Next() {
		isExcluded, err := doublestar.Match(excludeIt.Value().(string), filePath)
		if err != nil {
			fmt.Println("ERROR: ", fmt.Errorf("exclusion glob error %e", err))
			return false
		}
		if isExcluded {
			return true
		}
	}
	return false
}

// SetGenerationEnabled sets whether the extension is enabled or not.
func (c *TypeScriptConfig) SetGenerationEnabled(enabled bool) {
	c.generationEnabled = enabled
}

// GenerationEnabled returns whether the extension is enabled or not.
func (c *TypeScriptConfig) GenerationEnabled() bool {
	return c.generationEnabled
}

func (c *TypeScriptConfig) SetNpmWorkspace(npm_workspace string) {
	c.npm_workspace = npm_workspace
}
func (c *TypeScriptConfig) NpmWorkspace() string {
	return c.npm_workspace
}

func (c *TypeScriptConfig) SetNpmPackageJSON(npm_package_json string) {
	c._npm_packages = nil
	c.npm_package_json = npm_package_json
}
func (c *TypeScriptConfig) GetNpmPackages() *treeset.Set {
	// Parse the npm_package_json file and build the list of knowns packages
	if c._npm_packages == nil {
		packages, err := parsePackageJSONFile(c.npm_workspace, filepath.Join(c.repoRoot, c.npm_package_json))

		if err != nil {
			fmt.Sprintln("WARNING: ", fmt.Errorf("failed to parse package.json %s: %w", c.npm_package_json, err))
			packages = treeset.NewWithStringComparator()
		}

		c._npm_packages = packages

		DEBUG("NPM Packages(@%s): %s", c.npm_workspace, packages.Values())
	}

	return c._npm_packages
}

func (c *TypeScriptConfig) GetNpmPackagesWorkspace() string {
	return c.npm_workspace
}

func (c *TypeScriptConfig) GetNpmPackage(imprt string) (string, bool) {
	for pkg := imprt; len(pkg) > 0 && pkg != "."; {
		if c.GetNpmPackages().Contains(pkg) {
			DEBUG("GetNpmPackage: %q => %q", imprt, pkg)

			return "@" + c.npm_workspace + "//" + pkg, true
		}
		pkg = filepath.Dir(pkg)
	}

	DEBUG("GetNpmPackage: %q => None", imprt)

	return "", false
}

// Adds a dependency to the list of ignored dependencies for
// a given package. Adding an ignored dependency to a package also makes it
// ignored on a subpackage.
func (c *TypeScriptConfig) AddIgnoredImport(imp string) {
	c.ignoreDependencies.Add(imp)
}

// Checks if a dependency is ignored in the given package or
// in one of the parent packages up to the workspace root.
func (c *TypeScriptConfig) IsDependencyIgnored(dep string) bool {
	config := c
	for config != nil {
		if config.ignoreDependencies.Contains(dep) {
			return true
		}
		config = config.parent
	}

	return false
}

// SetValidateImportStatements sets whether TypeScript import statements should be
// validated or not. It throws an error if this is set multiple times, i.e. if
// the directive is specified multiple times in the Bazel workspace.
func (c *TypeScriptConfig) SetValidateImportStatements(validate bool) {
	c.validateImportStatements = validate
}

// ValidateImportStatements returns whether the TypeScript import statements should
// be validated or not. If this option was not explicitly specified by the user,
// it defaults to true.
func (c *TypeScriptConfig) ValidateImportStatements() bool {
	return c.validateImportStatements
}

// SetEnvironment sets the TypeScirpt/JS environment type
func (c *TypeScriptConfig) SetEnvironmentType(envType EnvironmentType) {
	c.environmentType = envType
}

// Environment returns the TypeScirpt/JS environment type
func (c *TypeScriptConfig) EnvironmentType() EnvironmentType {
	return c.environmentType
}

// SetLibraryNamingConvention sets the ts_project target naming convention.
func (c *TypeScriptConfig) SetLibraryNamingConvention(libraryNamingConvention string) {
	c.libraryNamingConvention = libraryNamingConvention
}

// RenderLibraryName returns the ts_project target name by performing all
// substitutions.
func (c *TypeScriptConfig) RenderLibraryName(packageName string) string {
	return strings.ReplaceAll(c.libraryNamingConvention, packageNameNamingConventionSubstitution, packageName)
}

// SetTestsNamingLibraryConvention sets the ts_project test target naming convention.
func (c *TypeScriptConfig) SetTestsNamingLibraryConvention(testsNamingConvention string) {
	c.testsNamingConvention = testsNamingConvention
}

// RenderTestName returns the ts_project test target name by performing all
// substitutions.
func (c *TypeScriptConfig) RenderTestsLibraryName(packageName string) string {
	return strings.ReplaceAll(c.testsNamingConvention, packageNameNamingConventionSubstitution, packageName)
}

func (c *TypeScriptConfig) SetSourceFileGlob(srcsFileGlob string) {
	c.srcsFileGlob = srcsFileGlob
}
func (c *TypeScriptConfig) IsSourceFile(filePath string) bool {
	if !isSourceFile(filePath) {
		return false
	}
	if c.srcsFileGlob == "" {
		return true
	}

	m, e := doublestar.Match(c.srcsFileGlob, filePath)

	if e != nil {
		fmt.Println("ERROR: ", fmt.Errorf("srcs file glob error %e", e))
		return false
	}

	return m
}

func (c *TypeScriptConfig) SetTestFileGlob(testsFileGlob string) {
	c.testsFileGlob = testsFileGlob
}
func (c *TypeScriptConfig) IsTestFile(filePath string) bool {
	if !isSourceFile(filePath) {
		return false
	}
	if c.testsFileGlob == "" {
		return false
	}

	m, e := doublestar.Match(c.testsFileGlob, filePath)

	if e != nil {
		fmt.Println("ERROR: ", fmt.Errorf("tests file glob error %e", e))
		return false
	}

	return m
}

func parsePackageJSONFile(npm_workspace, npm_package_json string) (*treeset.Set, error) {
	content, err := os.ReadFile(npm_package_json)
	if err != nil {
		return nil, err
	}

	return parsePackageJSON(npm_workspace, content)
}

type NpmPackageJsonStruct struct {
	Dependencies    map[string]string `json:"dependencies"`
	DevDependencies map[string]string `json:"devDependencies"`
}

func parsePackageJSON(npm_workspace string, npm_package_json []byte) (*treeset.Set, error) {
	data := NpmPackageJsonStruct{}

	parseError := json.Unmarshal(npm_package_json, &data)
	if parseError != nil {
		return nil, parseError
	}

	pkgs := treeset.NewWithStringComparator()

	for d := range data.Dependencies {
		pkgs.Add(d)
	}
	for d := range data.DevDependencies {
		pkgs.Add(d)
	}

	return pkgs, nil
}
