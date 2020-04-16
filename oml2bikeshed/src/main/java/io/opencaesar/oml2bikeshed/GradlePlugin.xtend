package io.opencaesar.oml2bikeshed

import org.gradle.api.Plugin
import org.gradle.api.Project

class GradlePlugin implements Plugin<Project> {
	
    override apply(Project project) {
    	val params = project.extensions.create('oml2bikeshed', Oml2BikeshedParams)
       	 
        project.getTasks().create("generateBikeshed").doLast([task|
	       	App.main("-i",  project.file(params.inputPath).absolutePath, "-o", project.file(params.outputPath).absolutePath, "-u", params.url)
        ])
	}
}

class Oml2BikeshedParams {
	public var String inputPath
    public var String outputPath;
    public var String url;
}