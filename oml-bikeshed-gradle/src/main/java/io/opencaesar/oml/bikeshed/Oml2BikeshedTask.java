/**
 * 
 * Copyright 2019-2021 California Institute of Technology ("Caltech").
 * U.S. Government sponsorship acknowledged.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 */
package io.opencaesar.oml.bikeshed;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;

public class Oml2BikeshedTask extends DefaultTask {
	
	public String inputCatalogPath;
	
	public String inputCatalogTitle;
	
	public String inputCatalogVersion;
    
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
		if (inputCatalogTitle != null) {
			args.add("-it");
			args.add(inputCatalogTitle);
		}
		if (inputCatalogVersion != null) {
			args.add("-iv");
			args.add(inputCatalogVersion);
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