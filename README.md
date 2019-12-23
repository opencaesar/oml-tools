# Bikeshed Generator for OML

[![Build Status](https://travis-ci.org/opencaesar/oml-bikeshed.svg?branch=master)](https://travis-ci.org/opencaesar/oml-bikeshed)
[ ![Download](https://api.bintray.com/packages/opencaesar/oml-bikeshed/oml2bikeshed/images/download.svg) ](https://bintray.com/opencaesar/oml-bikeshed/oml2bikeshed/_latestVersion)

An [Bikeshed](https://github.com/tabatkins/bikeshed) generator for [Ecore](https://www.eclipse.org/modeling/emf/)

## Clone
```
    git clone https://github.com/opencaesar/oml-bikeshed.git
    cd oml-bikeshed
```
      
## Build
Requirements: java 8, node 8.x, 
```
    cd oml2bikeshed
    ./gradlew build
```

## Run from Terminal

MacOS/Linux:
```
    cd oml2bikeshed
    ./gradlew run --args="-i path/to/oml/folder -o path/to/bikeshed/folder -u <url>"
```
Windows:
```
    cd oml2bikeshed
    gradlew.bat run --args="-i path/to/oml/folder -o path/to/bikeshed/folder -u <url>"
```

## Run from Gradle

Add the following to an OML project's build.gradle:
```
buildscript {
	repositories {
		maven { url 'https://dl.bintray.com/opencaesar/oml-bikeshed' }
		maven { url 'https://dl.bintray.com/opencaesar/oml' }
		jcenter()
	}
	dependencies {
		classpath 'io.opencaesar.bikeshed:oml2bikeshed:+'
	}
}

apply plugin: 'io.opencaesar.oml2bikeshed'

oml2bikeshed {
	inputPath = 'src/main/oml'
	outputPath = 'src/main/bikeshed-gen'
	url = '<url>'
}

task clean(type: Delete) {
	delete 'src/main/bikeshed-gen'
}
```

## Release

Replace \<version\> by the version, e.g., 1.2
```
  git tag -a <version> -m "<version>"
  git push origin <version>
```
