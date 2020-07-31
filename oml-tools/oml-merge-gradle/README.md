# OML Merge

[ ![Download](https://api.bintray.com/packages/opencaesar/oml-tools/oml-merge-gradle/images/download.svg) ](https://bintray.com/opencaesar/oml-tools/oml-merge-gradle/_latestVersion)

A tool to merge one or more OML catalogs into a new OML catalog.

## Run as Gradle Task

```
buildscript {
	repositories {
		maven { url 'https://dl.bintray.com/opencaesar/oml-tools' }
  		mavenCentral()
		jcenter()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-merge-gradle:+'
	}
}
task omlMerge(type:io.opencaesar.oml.merge.OmlMergeTask) {
	inputCatalogPaths = [
        file('path/to/input/oml/catalog.xml'),
        file('path/to/input/oml/catalog.xml')
    ] [Required, one or more]
	outputCatalogPath = file('path/to/output/oml/catalog.xml') [Required]
}               
```