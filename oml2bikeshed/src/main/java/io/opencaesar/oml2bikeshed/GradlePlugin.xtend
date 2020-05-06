package io.opencaesar.oml2bikeshed

import org.gradle.api.Plugin
import org.gradle.api.Project

class GradlePlugin implements Plugin<Project> {
	
    override apply(Project project) {
    	val ^extension = project.extensions.create('oml2bikeshed', Oml2BikeshedExtension)
        project.getTasks().create("generateBikeshed").doLast [
	       	App.main(
	       		"-i",  project.file(^extension.inputPath).absolutePath, 
	       		"-o", project.file(^extension.outputPath).absolutePath, 
	       		"-u", ^extension.url
	       	)
        ]
	}
}

class Oml2BikeshedExtension {
	public var String inputPath
    public var String outputPath;
    public var String url;
}