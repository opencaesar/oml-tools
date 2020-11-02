# OML Validate

[ ![Download](https://api.bintray.com/packages/opencaesar/oml-tools/oml-validate/images/download.svg) ](https://bintray.com/opencaesar/oml-tools/oml-validate/_latestVersion)

A tool to validate an OML catalog.

## Run as CLI

MacOS/Linux:
```
./gradlew oml-validate:run --args="..."
```
Windows:
```
gradlew.bat oml-validate:run --args="..."
```
Args:
```
--input-catalog-path | -i path/to/input/oml/catalog [Required]
--output-report-path | -o path/to/output/report.txt [Optional]
```

## Run as Gradle Task
```
buildscript {
	repositories {
		maven { url 'https://dl.bintray.com/opencaesar/oml-tools' }
  		mavenCentral()
		jcenter()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-validate-gradle:+'
	}
}
task omlValidate(type:io.opencaesar.oml.validate.OwlValidateTask) {
	inputCatalogPath = file('path/to/input/oml/catalog.xml') [Required]
	outputReportPath = file('path/to/output/report.txt') [Optional]
}               
```

NOTE: If the outputReportPath is not specified, the error report will be printed in the standard error stream.