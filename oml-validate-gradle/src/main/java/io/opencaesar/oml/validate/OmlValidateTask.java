package io.opencaesar.oml.validate;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;

public class OmlValidateTask extends DefaultTask {
	
	public String inputCatalogPath;
    
    public String outputReportPath;
    
    @TaskAction
    public void run() {
		List<String> args = new ArrayList<String>();
		if (inputCatalogPath != null) {
			args.add("-i");
			args.add(inputCatalogPath);
		}
		if (outputReportPath != null) {
			args.add("-o");
			args.add(outputReportPath);
		}
		try {
        	OmlValidateApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}