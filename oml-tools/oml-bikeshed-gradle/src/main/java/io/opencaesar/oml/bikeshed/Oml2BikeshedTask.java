package io.opencaesar.oml.bikeshed;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;

public class Oml2BikeshedTask extends DefaultTask {
	
	public String inputCatalogPath;
    
    public String outputFolderPath;
    
    public String rootOntologyIri;
    
    public String publishUrl;

    @TaskAction
    public void run() {
		List<String> args = new ArrayList<String>();
		if (inputCatalogPath != null) {
			args.add("-i");
			args.add(inputCatalogPath);
		}
		if (outputFolderPath != null) {
			args.add("-o");
			args.add(outputFolderPath);
		}
		if (publishUrl != null) {
			args.add("-u");
			args.add(publishUrl);
		}
		if (rootOntologyIri != null) {
			args.add("-r");
			args.add(rootOntologyIri);
		}
		try {
        	Oml2BikeshedApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}