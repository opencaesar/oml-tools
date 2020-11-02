# OML Bikeshed

[ ![Download](https://api.bintray.com/packages/opencaesar/oml-tools/oml-bikeshed/images/download.svg) ](https://bintray.com/opencaesar/oml-tools/oml-bikeshed/_latestVersion)

A tool to generate Bikeshed specification from an OML catalog.

## Run as CLI

MacOS/Linux:
```
cd oml-bikeshed
./gradlew oml-bikeshed:run --args="..."
```
Windows:
```
cd oml-bikeshed
gradlew.bat oml-bikeshed:run --args="..."
```
Args:
```
--input-catalog-path | -i path/to/input/oml/catalog [Required]
--root-ontology-iri | -r iri-of-root-ontology [Optional]
--output-folder-path | -o path/to/output/bikeshed/folder [Required]
--publish-url | -u URL where the Bikeshed spec will be published [Required]
```

Note:when '-r' is specified, only the root ontology and its import closure will be included; otherwise the entire catalog will be include

## Run as Gradle Task
```
buildscript {
	repositories {
		maven { url 'https://dl.bintray.com/opencaesar/oml-tools' }
  		mavenCentral()
		jcenter()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-bikeshed-gradle:+'
	}
}
task oml2Bikeshed(type:io.opencaesar.oml.bikeshed.Oml2BikeshedTask) {
	inputPath = file('path/to/input/oml/folder') [Required]
	rootOntologyIri = iri-of-root-ontology [Optional]
	outputPath = file('path/to/output/bikeshed/folder') [Required]
    publishUrl = 'URL where the Bikeshed spec will be published' [Required]
}               
```