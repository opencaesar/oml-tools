# oml-bikeshed
A [Bikeshed](https://tabatkins.github.io/bikeshed/) spec generator from [OML](https://opencaesar.github.io/oml-spec/)

[![Build Status](https://travis-ci.org/opencaesar/oml-bikeshed.svg?branch=master)](https://travis-ci.org/opencaesar/oml-bikeshed)


## Build

```
cd oml2bikeshed
./gradlew build
```

## Run Natively

```
cd oml2bikeshed
./gradlew run --args="-i <input folder> -o <output folder> -u <url>"
```
where:
* "<input folder>" is a folder containing some OML vocabularies (can be the root of a nested structure)
* "<output folder>" is a folder where output bikeshed files will be written
* "<url>" is the URL root where documents will be deployed

Generally, the output folder should be a temporary folder. A subsequent step will run bikeshed on each generated
specification in that folder to convert it to html.

## Create docker image

A docker file is provided specifying a docker image containing this application. To generate the image, run:

```
docker build . -t <image name>
```

## Running from docker image

Assume the docker image name is "oml2bikeshed" and you have already pulled this image or built it locally.

The docker image maps two folders: /input and /output which will be passed to the app when it runs.

```
docker run <image name> -v <input folder>:/input <output folder>:/output [<url>]
```
where <input folder> is the directory path to the folder containing the target vocabularies in OML, and <output folder> is the directory path to an empty folder where the output bikeshed files will be written. The optional <url> is the target root location where the documentation will be published (default is https://opencaesar.github.io/vocabularies).

A shell script is provided as a shortcut to running the docker image (you still need to have docker running):

```
oml2bsdocker.sh <input folder> <output folder> [<url>]
```

## Publish docker image

TBD
