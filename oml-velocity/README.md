# OML Velocity

[![Release](https://img.shields.io/github/v/tag/opencaesar/oml-tools?label=release)](https://github.com/opencaesar/oml-tools/releases/latest)

A tool to instantiate OML Velocity templates.

## Run as CLI

MacOS/Linux:
```
./gradlew oml-velocity:run --args="..."
```
Windows:
```
gradlew.bat oml-velocity:run --args="..."
```
Args:
```
-t | --template-folder path/to/base/template/folder [Required]
-i | --template-include a (glob) pattern matching the template files to include [Optional, default: **/*.oml]
-r | --template-rename A string old:new to find and replace in a template name [Optional]
-k | --template-key-value a key=value pair to pass as a context when instantiating templates [Optional]
-o | --output-folder path/to/output/folder [Required]
-v | --version displays app version [Optional]
-h | --help displays summary of options [Optional]
-d | --debug displays shows debug logging statements [Optional]
```

## Run as Gradle Task
```
buildscript {
	repositories {
  		mavenCentral()
	}
	dependencies {
		classpath 'io.opencaesar.oml:oml-velocity-gradle:+'
	}
}
task omlVelocity(type:io.opencaesar.oml.velocity.OmlVelocityTask) {
	templateFolder = file('path/to/base/template/folder') [Required]
	templateInclude = '**/namespace/*.oml' [Optional]
	templateRename = 'old:new' [Optional]
	templateKeyValues = ["key1=value1", "key2=value2"] [Optional]
	outputFolder = file('path/to/base/output/folder') [Required]
}               
```
