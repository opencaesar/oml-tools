package io.opencaesar.oml.merge;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;

public class OmlMergeTask extends DefaultTask {

	public Collection<File> inputZipPaths = null;
	
	public Collection<File> inputFolderPaths = null;
	
	public Collection<File> inputCatalogPaths = null;
    
    public File outputCatalogFolder;
    
    public boolean generateOutputCatalog;

    public boolean debug;

    @TaskAction
    public void run() {
    	List<String> args = new ArrayList<String>();
    	if (null != inputZipPaths) {
			for (File inputZipPath : inputZipPaths) {
				args.add("-z");
				args.add(inputZipPath.getAbsolutePath());
			}
		}
    	if (null != inputFolderPaths) {
			for (File inputFolderPath : inputFolderPaths) {
				args.add("-f");
				args.add(inputFolderPath.getAbsolutePath());
			}
		}
    	if (null != inputCatalogPaths) {
			for (File inputCatalogPath : inputCatalogPaths) {
				args.add("-c");
				args.add(inputCatalogPath.getAbsolutePath());
			}
		}
		if (outputCatalogFolder != null) {
			args.add("-o");
			args.add(outputCatalogFolder.getAbsolutePath());
		}
		if (generateOutputCatalog) {
			args.add("-g");
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