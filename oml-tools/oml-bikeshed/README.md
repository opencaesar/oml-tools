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
-i path/to/input/oml/folder
-o path/to/output/bikeshed/folder
-u URL where the Bikeshed documents will be published
```
