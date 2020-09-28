package io.opencaesar.oml.merge;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;

public class OmlMergeTask extends DefaultTask {

	public List<String> inputZipPaths = null;
	public List<String> inputFolderPaths = null;
	public List<String> inputCatalogPaths = null;
    
    public String outputCatalogFolder;
    
    public boolean debug;

    @TaskAction
    public void run() {
    	List<String> args = new ArrayList<String>();
		for (String inputZipPath : inputZipPaths) {
			args.add("-z");
			args.add(inputZipPath);
		}
		for (String inputFolderPath : inputFolderPaths) {
			args.add("-f");
			args.add(inputFolderPath);
		}
		for (String inputCatalogPath : inputCatalogPaths) {
			args.add("-c");
			args.add(inputCatalogPath);
		}
		if (outputCatalogFolder != null) {
			args.add("-o");
			args.add(outputCatalogFolder);
		}
		if (debug) {
			args.add("-d");
		}
		try {
			OmlMergeApp.main(args.toArray(new String[args.size()]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}