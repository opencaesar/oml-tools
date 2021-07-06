# OML Validate

[![Release](https://img.shields.io/github/v/tag/opencaesar/oml-tools?label=release)](https://github.com/opencaesar/oml-tools/releases/latest)

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
  		mavenCentral()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-validate-gradle:+'
	}
}
task omlValidate(type:io.opencaesar.oml.validate.OmlValidateTask) {
	inputCatalogPath = file('path/to/input/oml/catalog.xml') [Required]
	outputReportPath = file('path/to/output/report.txt') [Optional]
}               
```

NOTE: If the outputReportPath is not specified, the error report will be printed in the standard error stream.
