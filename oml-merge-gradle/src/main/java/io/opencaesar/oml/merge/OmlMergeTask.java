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
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.file.DirectoryProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputFiles;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.OutputDirectory;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

public abstract class OmlMergeTask extends DefaultTask {

	public Collection<File> inputZipPaths;

    public void setInputZipPaths(Collection<File> files) {
    	inputZipPaths = files;
   		getInputFiles().from(files);
    }

    public Collection<File> inputFolderPaths = null;

    public void setInputFolderPaths(Collection<File> files) {
    	inputFolderPaths = files;
  		getInputFiles().from(files);
    }

    public Collection<File> inputCatalogPaths;

    public void setInputCatalogPaths(Collection<File> files) {
    	inputCatalogPaths = files;
  		getInputFiles().from(files);
    }

    @Incremental
    @InputFiles
    public abstract ConfigurableFileCollection getInputFiles();

	@OutputDirectory
	public abstract DirectoryProperty getOutputCatalogFolder();
    
	@Optional
    @Input
    public abstract Property<Boolean> getGenerateOutputCatalog();

	@Input
	@Optional
	public abstract Property<Boolean> getDebug();

    @TaskAction
    public void run() {
    	List<String> args = new ArrayList<>();
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
		if (getOutputCatalogFolder().isPresent()) {
			args.add("-o");
			args.add(getOutputCatalogFolder().get().getAsFile().getAbsolutePath());
		}
		if (getGenerateOutputCatalog().isPresent()) {
			if (getGenerateOutputCatalog().get()) {
				args.add("-g");
			}
		}
		if (getDebug().isPresent() && getDebug().get()) {
			args.add("-d");
		}
		try {
    		OmlMergeApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}