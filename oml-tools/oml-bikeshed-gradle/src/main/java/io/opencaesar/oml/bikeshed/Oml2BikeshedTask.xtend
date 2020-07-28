package io.opencaesar.oml.bikeshed

import java.util.ArrayList
import org.gradle.api.DefaultTask
import org.gradle.api.tasks.TaskAction

class Oml2BikeshedTask extends DefaultTask {
	
	public var String inputPath
    
    public var String outputPath;
    
    public var String url;

    @TaskAction
    def run() {
		val args = new ArrayList
		if (inputPath !== null) {
			args += #["-i", inputPath]
		}
		if (outputPath !== null) {
			args += #["-o", outputPath]
		}
		if (url !== null) {
			args += #["-u", url]
		}
        Oml2BikeshedApp.main(args)
	}
}