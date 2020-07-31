# OML Bikeshed

[ ![Download](https://api.bintray.com/packages/opencaesar/oml-tools/oml-bikeshed/images/download.svg) ](https://bintray.com/opencaesar/oml-tools/oml-bikeshed/_latestVersion)

A tool to generate Bikeshed specification from an OML catalog.

## Run as CLI

MacOS/Linux:
```
cd oml-bikeshed
./gradlew owl-bikeshed:run --args="..."
```
Windows:
```
cd oml-bikeshed
gradlew.bat owl-bikeshed:run --args="..."
```
Args:
```
--input-path | -i path/to/input/oml/folder [Required]
--output-path | -o path/to/output/bikeshed/folder [Required]
--url | -u URL where the Bikeshed spec will be published [Required]
```

## [Run as Gradle Task](../oml-bikeshed-gradle/README.md)