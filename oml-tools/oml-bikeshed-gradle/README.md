# OML Bikeshed

[ ![Download](https://api.bintray.com/packages/opencaesar/oml-tools/oml-bikeshed-gradle/images/download.svg) ](https://bintray.com/opencaesar/oml-tools/oml-bikeshed-gradle/_latestVersion)

A tool to generate Bikeshed specification from an OML catalog.

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
	outputPath = file('path/to/output/bikeshed/folder') [Required]
    url = 'URL where the Bikeshed spec will be published' [Required]
}               
```