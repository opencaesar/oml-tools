package io.opencaesar.oml.merge;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;

public class OmlMergeTask extends DefaultTask {
	
	public List<String> inputCatalogPaths = null;
    
    public String outputCatalogPath;
    
    public boolean debug;

    @TaskAction
    public void run() {
    	List<String> args = new ArrayList<String>();
		for (String inputCatalogPath : inputCatalogPaths) {
			args.add("-i");
			args.add(inputCatalogPath);
		}
		if (outputCatalogPath != null) {
			args.add("-o");
			args.add(outputCatalogPath);
		}
		if (debug) {
			args.add("-d");
		}
        OmlMergeApp.main(args.toArray(new String[args.size()]));
	}
}