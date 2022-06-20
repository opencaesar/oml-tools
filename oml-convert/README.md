# OML Convert

[![Release](https://img.shields.io/github/v/tag/opencaesar/oml-tools?label=release)](https://github.com/opencaesar/oml-tools/releases/latest)

A tool to convert OML files to another persistence format

## Run as CLI

MacOS/Linux:
```
./gradlew oml-convert:run --args="..."
```
Windows:
```
gradlew.bat oml-convert:run --args="..."
```
Args:
```
-i | --input-catalog-path path/to/input/oml/catalog.xml [Required]
-o | --output-catalog-path path/to/output/oml/catalog.xml [Required]
-f | --output-file-extension [Required, options: oml, omlxmi, omljson]
-h | --help displays [Summary of options, Optional]
-d | --debug displays [Shows debug logging statements, Optional]
```

## Run as Gradle Task
```
buildscript {
	repositories {
  		mavenCentral()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-convert-gradle:+'
	}
}
task omlConvert(type:io.opencaesar.oml.convert.OmlConvertTask) {
	inputCatalogPath = file('path/to/input/oml/catalog.xml') [Required] 
	outputCatalogPath = file('path/to/output/oml/catalog.xml') [Required]
	outputFileExtension = 'omlxmi' [Required, options: oml, omlxmi, omljson]
}               
```
