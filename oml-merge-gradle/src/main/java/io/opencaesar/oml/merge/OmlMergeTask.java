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