# Bikeshed Generator for OML

[![Build Status](https://travis-ci.org/opencaesar/oml-bikeshed.svg?branch=master)](https://travis-ci.org/opencaesar/oml-bikeshed)
[ ![Download](https://api.bintray.com/packages/opencaesar/oml-bikeshed/oml2bikeshed/images/download.svg) ](https://bintray.com/opencaesar/oml-bikeshed/oml2bikeshed/_latestVersion)

A [Bikeshed](https://github.com/tabatkins/bikeshed) generator for [OML](https://opencaesar.github.io/oml) that can be run as an app from the Terminal or as a Gradle plugin.

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

## Run as CLI

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
Optionally install it in your local maven repo (if you modified it)
```
    ./gradlew install
```
In a gradle.build script, add the following:
```
buildscript {
	repositories {
		mavenLocal()
		maven { url 'https://dl.bintray.com/opencaesar/oml-bikeshed' }
		maven { url 'https://dl.bintray.com/opencaesar/oml' }
	}
	dependencies {
		classpath 'io.opencaesar.bikeshed:oml2bikeshed:+'
	}
}

apply plugin: 'io.opencaesar.oml2bikeshed'

oml2bikeshed {
	inputPath = 'path/to/oml/folder'
	outputPath = 'path/to/bikeshed/folder'
	url = '<url>'
}

task build {
	dependsOn generateBikeshed
}

task clean(type: Delete) {
	delete 'path/to/bikeshed/folder'
}
```

## Release

Replace \<version\> by the version, e.g., 1.2
```
  git tag -a <version> -m "<version>"
  git push origin <version>
```
