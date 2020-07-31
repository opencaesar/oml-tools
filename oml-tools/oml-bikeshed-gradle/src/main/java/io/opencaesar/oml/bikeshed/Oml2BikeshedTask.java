package io.opencaesar.oml.bikeshed;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;

public class Oml2BikeshedTask extends DefaultTask {
	
	public String inputPath;
    
    public String outputPath;
    
    public String url;

    @TaskAction
    public void run() {
		List<String> args = new ArrayList<String>();
		if (inputPath != null) {
			args.add("-i");
			args.add(inputPath);
		}
		if (outputPath != null) {
			args.add("-o");
			args.add(outputPath);
		}
		if (url != null) {
			args.add("-u");
			args.add(url);
		}
        Oml2BikeshedApp.main(args.toArray(new String[0]));
	}
}