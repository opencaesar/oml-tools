#!/bin/bash
# Run the converter in docker
# Input OML folder is mapped to /input
# Output bikeshed folder is mapped to /output
# URL argument is passed as environment variable $URL

#java -cp /app/oml2bikeshed-0.1.0.jar io.opencaesar.oml2bikeshed.App -args="-i /input -o /output -u $URL"
echo "LAUNCH OML2BIKESHED URL=$URL"

ls -al /input

./bin/oml2bikeshed -i /input -o /output -u $URL
