# OML Merge

[ ![Download](https://api.bintray.com/packages/opencaesar/oml-tools/oml-merge/images/download.svg) ](https://bintray.com/opencaesar/oml-tools/oml-merge/_latestVersion)

A tool to merge one or more OML catalogs into a new OML catalog.

## Run as CLI

MacOS/Linux:
```
cd oml-merge
./gradlew owl-merge:run --args="..."
```
Windows:
```
cd oml-merge
gradlew.bat owl-merge:run --args="..."
```
Args:
```
--input-catalog-path | -i path/to/input/oml/catalog.xml [Required, one or more]
--output-catalog-path | -o path/to/output/oml/catalog.xml [Required]
```

## [Run as Gradle Task](../oml-merge-gradle/README.md)