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
import java.util.Collections;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.file.DirectoryProperty;
import org.gradle.api.provider.ListProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputFiles;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.OutputDirectory;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

/**
 * A gradle task to invoke the OmlMerge tool 
 */
public abstract class OmlMergeTask extends DefaultTask {

	/**
	 * Creates a new OmlMergeTask object
	 */
	public OmlMergeTask() {
	}

	/**
	 * The paths to input OML zip archives.
	 * 
	 * @return File List Property
	 */
    @Input
    @Optional
    public abstract ListProperty<File> getInputZipPaths();

	/**
	 * The paths to input OML folders.
	 * 
	 * @return File List Property
	 */
    @Input
    @Optional
   public abstract ListProperty<File> getInputFolderPaths();

	/**
	 * The paths to input OML catalog files.
	 * 
	 * @return File List Property
	 */
    @Input
    @Optional
   public abstract ListProperty<File> getInputCatalogPaths();

	/**
	 * The path to output OML folder where a basic OML catalog will be created.
	 * 
	 * @return Directory Property
	 */
    @OutputDirectory
    public abstract DirectoryProperty getOutputCatalogFolder();
    
	/**
	 * Whether to generate a catalog file in the output folder path.
	 * 
	 * @return Boolean Property
	 */
	@Optional
    @Input
    public abstract Property<Boolean> getGenerateOutputCatalog();

	/**
	 * Whether to show debug logging statements.
	 * 
	 * @return Boolean Property
	 */
    @Input
    @Optional
	public abstract Property<Boolean> getDebug();

	/**
	 * The input OML files
	 * 
	 * @return ConfigurableFileCollection
	 */
    @Incremental
    @InputFiles
    protected ConfigurableFileCollection getInputFiles() {
    	if (!getInputZipPaths().get().isEmpty())
    		return getProject().files(getInputZipPaths().get());
    	if (!getInputFolderPaths().get().isEmpty())
    		return getProject().files(getInputFolderPaths());
    	if (!getInputCatalogPaths().get().isEmpty())
    		return getProject().files(getInputCatalogPaths());
		return getProject().files(Collections.EMPTY_LIST);
    }

    /**
     * The gradle task action logic.
     */
    @TaskAction
    public void run() {
    	List<String> args = new ArrayList<>();
    	if (!getInputZipPaths().get().isEmpty()) {
			for (File inputZipPath : getInputZipPaths().get()) {
				args.add("-z");
				args.add(inputZipPath.getAbsolutePath());
			}
		}
    	if (!getInputFolderPaths().get().isEmpty()) {
			for (File inputFolderPath : getInputFolderPaths().get()) {
				args.add("-f");
				args.add(inputFolderPath.getAbsolutePath());
			}
		}
    	if (!getInputCatalogPaths().get().isEmpty()) {
			for (File inputCatalogPath : getInputCatalogPaths().get()) {
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