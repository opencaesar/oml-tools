# OML Bikeshed

[![Release](https://img.shields.io/github/v/tag/opencaesar/oml-tools?label=release)](https://github.com/opencaesar/oml-tools/releases/latest)

A tool to generate Bikeshed specification from an OML catalog.

## Run as CLI

MacOS/Linux:
```
./gradlew oml-bikeshed:run --args="..."
```
Windows:
```
gradlew.bat oml-bikeshed:run --args="..."
```
Args:
```
--input-catalog-path | -i path/to/input/oml/catalog [Required]
--input-catalog-title | -it title [Optional]
--input-catalog-version | -iv version [Optional]
--root-ontology-iri | -r iri-of-root-ontology [Required]
--output-folder-path | -o path/to/output/bikeshed/folder [Required]
--publish-url | -u URL where the Bikeshed spec will be published [Required]
```

Note:when '-r' is specified, only the root ontology and its import closure will be included; otherwise the entire catalog will be include

## Run as Gradle Task
```
buildscript {
	repositories {
  		mavenCentral()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-bikeshed-gradle:+'
	}
}
task oml2Bikeshed(type:io.opencaesar.oml.bikeshed.Oml2BikeshedTask) {
	inputCatalogPath = file('path/to/input/oml/catalog') [Required]
	inputCatalogTitle = project.title [Optional]
	inputCatalogVersion = project.version [Optional]
	rootOntologyIri = iri-of-root-ontology [Required]
	outputFolderPath = file('path/to/output/bikeshed/folder') [Required]
	publishUrl = 'URL where the Bikeshed spec will be published' [Required]
}               
```
