package gazelle

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/bazelbuild/bazel-gazelle/label"
	"github.com/bazelbuild/bazel-gazelle/language"
	"github.com/bazelbuild/bazel-gazelle/rule"
	"github.com/emirpasic/gods/lists/singlylinkedlist"
	"github.com/emirpasic/gods/sets/treeset"
)

const (
	// The filename (with any of the TS extensions) imported when importing a directory
	indexFileName = "index"
)

func (c *TypeScript) GetNamedPackage(imprt string) (string, bool) {
	for pkg := imprt; len(pkg) > 0 && pkg != "."; {
		if target := c.Packages[pkg]; target != "" {
			return target, true
		}
		pkg = filepath.Dir(pkg)
	}

	return "", false
}

func (ts *TypeScript) CollectNamedPackages(ruleDir string, rules []*rule.Rule) {
	for _, r := range rules {
		if r.Kind() == "js_library" {
			if pkg := r.AttrString("package_name"); pkg != "" {
				ts.Packages[pkg] = "//" + ruleDir + ":" + r.Name()
			}
		}
	}
}

// GenerateRules extracts build metadata from source files in a directory.
// GenerateRules is called in each directory where an update is requested
// in depth-first post-order.
func (ts *TypeScript) GenerateRules(args language.GenerateArgs) language.GenerateResult {
	cfgs := args.Config.Exts[languageName].(Configs)
	cfg := cfgs[args.Rel]

	// When we return empty, we mean that we don't generate anything, but this
	// still triggers the indexing for all the TypeScript targets in this
	// package.
	if !cfg.GenerationEnabled() {
		return language.GenerateResult{}
	}

	// If this directory has not been declared as a bazel package it will have been
	// including in the parent BUILD file.
	if !isBazelPackage(args.Dir) {
		return language.GenerateResult{}
	}

	// Collect named modules from this target
	ts.CollectNamedPackages(args.Rel, args.File.Rules)

	// Collect all source files
	sourceFiles, dataFiles, collectErr := collectSourceFiles(cfg, args)
	if collectErr != nil {
		log.Printf("ERROR: %v\n", collectErr)
		return language.GenerateResult{}
	}

	DEBUG("SOURCE(%q): %s", args.Rel, sourceFiles.Values())

	// Divide src vs test files
	libSourceFiles := treeset.NewWithStringComparator()
	testSourceFiles := treeset.NewWithStringComparator()

	for _, f := range sourceFiles.Values() {
		file := f.(string)
		if cfg.IsTestFile(file) {
			testSourceFiles.Add(file)
		} else if cfg.IsSourceFile(file) {
			libSourceFiles.Add(file)
		}
	}

	// Build the GenerateResult with src and test rules
	var result language.GenerateResult

	addProjectRule(
		cfg,
		args,
		cfg.RenderLibraryName(filepath.Base(args.Dir)),
		libSourceFiles,
		dataFiles,
		&result,
	)

	addProjectRule(
		cfg,
		args,
		cfg.RenderTestsLibraryName(filepath.Base(args.Dir)),
		testSourceFiles,
		dataFiles,
		&result,
	)

	return result
}

func addProjectRule(cfg *TypeScriptConfig, args language.GenerateArgs, targetName string, sourceFiles, dataFiles *treeset.Set, result *language.GenerateResult) {
	// Generate nothing if there are no source files
	if sourceFiles.Empty() {
		// If there is already a BUILD then potentially clean it up
		if args.File != nil {
			// Remove any exiting instance of this rule project rule
			for _, r := range args.File.Rules {
				if r.Name() == targetName && r.Kind() == tsProjectKind {
					result.Empty = append(result.Empty, rule.NewRule(r.Kind(), r.Name()))
				}
			}
		}

		return
	}

	// If a build already exists check for name-collisions with the rule being generated
	if args.File != nil {
		checkCollisionErrors(targetName, args)
	}

	// Data files imported by sourceFiles
	sourceDataFiles := treeset.NewWithStringComparator()

	// Collect import statements from source
	importedFiles := treeset.NewWith(importStatementComparator)

	// TODO(jbedard): parse files concurrently
	sourceFileIt := sourceFiles.Iterator()
	for sourceFileIt.Next() {
		filePath := sourceFileIt.Value().(string)
		fileImports, err := parseFile(filepath.Join(args.Dir, filePath))

		if err != nil {
			fmt.Println("Parse Error:", fmt.Errorf("%q: %v", filePath, err))
		} else {
			for _, importPath := range fileImports {
				if !cfg.IsDependencyIgnored(importPath) {
					importPath = toWorkspacePath(args.Rel, filePath, importPath)

					// If importing a local data file that can be compiled as ts source
					// then add it to the sourceDataFiles to be included in the srcs
					if dataFiles.Contains(importPath) {
						sourceDataFiles.Add(importPath)
					}

					// Record all imports. Maybe local, maybe data etc.
					importedFiles.Add(ImportStatement{
						Path:       importPath,
						SourcePath: filePath,
					})
				}

				DEBUG("IMPORT(%q): %q", filePath, importPath)
			}
		}
	}

	// Add any imported data files as sources
	sourceFiles.Add(sourceDataFiles.Values()...)

	tsProject := rule.NewRule(tsProjectKind, targetName)
	tsProject.SetAttr("srcs", sourceFiles.Values())

	result.Gen = append(result.Gen, tsProject)
	result.Imports = append(result.Imports, importedFiles)
}

// Parse the passed file for import statements
func parseFile(filePath string) ([]string, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	return NewParser().ParseImports(filePath, string(content)), nil
}

// isBazelPackage determines if the directory is a Bazel package by probing for
// the existence of a known BUILD file name.
func isBazelPackage(dir string) bool {
	for _, buildFilename := range buildFileNames {
		path := filepath.Join(dir, buildFilename)
		if _, err := os.Stat(path); err == nil {
			return true
		}
	}
	return false
}

func collectSourceFiles(cfg *TypeScriptConfig, args language.GenerateArgs) (*treeset.Set, *treeset.Set, error) {
	sourceFiles := treeset.NewWithStringComparator()
	dataFiles := treeset.NewWithStringComparator()

	// Source files
	for _, f := range args.RegularFiles {
		if isSourceFile(f) {
			sourceFiles.Add(f)
		} else if isDataFile(f) {
			dataFiles.Add(f)
		}
	}

	// TODO(jbedard): record generated non-source files (args.GenFiles, args.OtherGen, ?)

	// Sub-Directory files
	// Find source files throughout the sub-directories of this BUILD.
	for _, d := range args.Subdirs {
		err := filepath.Walk(
			filepath.Join(args.Dir, d),
			func(filePath string, info os.FileInfo, err error) error {
				// Propagate errors.
				if err != nil {
					return err
				}

				// If we are visiting a directory recurse if it is not a bazel package.
				if info.IsDir() {
					if isBazelPackage(filePath) {
						return filepath.SkipDir
					}

					return nil
				}

				// Excxluded files. Must be done manually on Subdirs unlike
				// the BUILD directory which gazelle filters automatically.
				f, _ := filepath.Rel(args.Dir, filePath)
				if cfg.IsFileExcluded(f) {
					return nil
				}

				// Otherwise the file is either source or potentially importable
				if isSourceFile(f) {
					sourceFiles.Add(f)
				} else if isDataFile(f) {
					dataFiles.Add(f)
				}

				return nil
			},
		)

		if err != nil {
			log.Printf("ERROR: %v\n", err)
			return nil, nil, err
		}
	}

	return sourceFiles, dataFiles, nil
}

// Check if a target with the same name we are generating alredy exists,
// and if it is of a different kind from the one we are generating. If
// so, we have to throw an error since Gazelle won't generate it correctly.
func checkCollisionErrors(tsProjectTargetName string, args language.GenerateArgs) {
	collisionErrors := singlylinkedlist.New()

	for _, t := range args.File.Rules {
		if t.Name() == tsProjectTargetName && t.Kind() != tsProjectKind {
			fqTarget := label.New("", args.Rel, tsProjectTargetName)
			err := fmt.Errorf("failed to generate target %q of kind %q: "+
				"a target of kind %q with the same name already exists. "+
				"Use the '# gazelle:%s' directive to change the naming convention.",
				fqTarget.String(), tsProjectKind, t.Kind(), LibraryNamingConvention)
			collisionErrors.Add(err)
		}
	}

	if !collisionErrors.Empty() {
		it := collisionErrors.Iterator()
		for it.Next() {
			log.Printf("ERROR: %v\n", it.Value())
		}
		os.Exit(1)
	}
}

// If the file is ts-compatible source code that may contain typescript imports
func isSourceFile(f string) bool {
	ext := filepath.Ext(f)

	// Currently any source files may be parsed as ts and may contain imports
	return len(ext) > 0 && sourceFileExtensions.Contains(ext[1:])
}

func isDataFile(f string) bool {
	ext := filepath.Ext(f)
	return len(ext) > 0 && dataFileExtensions.Contains(ext[1:])
}

// Strip extensions off of a path if it can be imported without the extension
func stripImportExtensions(f string) string {
	if !isSourceFile(f) {
		return f
	}

	return f[:len(f)-len(filepath.Ext(f))]
}

// Normalize the given import statement from a relative path
// to a path relative to the workspace.
func toWorkspacePath(pkg, importFrom, importPath string) string {
	// Convert relative to workspace-relative
	if importPath[0] == '.' {
		importPath = filepath.Join(pkg, filepath.Dir(importFrom), importPath)
	}

	// Clean any extra . / .. etc
	return filepath.Clean(importPath)
}

// If the file is an index it can be imported with the directory name
func isIndexFile(f string) bool {
	if !isSourceFile(f) {
		return false
	}

	f = filepath.Base(f)
	f = stripImportExtensions(f)

	return f == indexFileName
}
