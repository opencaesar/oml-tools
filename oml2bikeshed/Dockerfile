
# Build assumes that the gradle project is already bulit and the resulting jar
# file is in ./build/libs. All we need to do is package the jar file with a
# compatible java8 jre.
# Usage:
# docker run <image> [-e URL=$url] -v /myinput:/input -v /myoutput:/output

## FIRST STAGE BUILD THE GRADLE APP IN DOCKER (we should upgrade our gradle dependencies)
#FROM gradle:4.10.2-jdk8 as builder

#COPY --chown=gradle:gradle . /home/gradle/src
#WORKDIR /home/gradle/src
#RUN gradle build
#RUN ls -al /home/gradle/src

## SECOND STAGE BUILD THE DEPLOYABLE IMAGE

FROM openjdk:8-jre-slim

LABEL org.opencontainers.image.title="openCAESAR OML Vocabulary to Bikeshed Documentation Generator"
LABEL org.opencontainers.image.description="Converts OML into Bikeshed specifications that Bikeshed can convert to html"
LABEL org.opencontainers.image.authors="Maged Elaasar, David Wagner"
LABEL org.opencontainers.image.source="https://github.com/opencaesar/oml-bikeshed"

# No license yet.
# LABEL org.opencontainers.image.licenses="Apache-2.0"

# URL defines the IRI root of the vocabularies. This is used in script to pass this argument to converter
ENV URL "https://github.com/opencaesar/vocabularies"

#COPY --from=builder /home/gradle/src/build/distributions/*.tar /app/
#COPY --from=builder /home/gradle/src/runindocker.sh /app/oml2bikeshed-0.1.0/
COPY ./build/distributions/*.tar /app/
COPY ./runindocker.sh /app/oml2bikeshed-0.1.0/
WORKDIR /app
RUN tar -xvf oml2bikeshed-0.1.0.tar
WORKDIR /app/oml2bikeshed-0.1.0

ENTRYPOINT ["/bin/sh","runindocker.sh"]
