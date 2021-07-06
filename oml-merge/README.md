# OML Merge

[![Release](https://img.shields.io/github/v/tag/opencaesar/oml-tools?label=release)](https://github.com/opencaesar/oml-tools/releases/latest)

A tool to merge one or more OML catalogs into a new OML catalog.

## Run as CLI

MacOS/Linux:
```
./gradlew oml-merge:run --args="..."
```
Windows:
```
gradlew.bat oml-merge:run --args="..."
```
Args:
```
--input-catalog-path | -i path/to/input/oml/catalog.xml [Optional, one or more]
--input-zip-path | -z path/to/input/oml/archive.zip [Optional, one or more]
--input-folder-path | -f path/to/input/oml/folder [Optional, one or more]
--output-folder-path | -o path/to/output/oml/folder [Required]
```
Note that one of the input arguments is required.

## Run as Gradle Task
```
buildscript {
	repositories {
  		mavenCentral()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-merge-gradle:+'
	}
}
task omlMerge(type:io.opencaesar.oml.merge.OmlMergeTask) {
	inputCatalogPaths = [ file('path/to/input/oml/catalog.xml') ] [Optional, one or more files]
	inputZipPaths = [ file('path/to/input/oml/archive.zip') ] [Optional, one or more files]
	inputFolderPaths = [ file('path/to/input/oml/folder') ] [Optional, one or more files]
	outputFolderPath = file('path/to/output/oml/folder') [Required]
}               
```
