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
package io.opencaesar.oml.convert;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.URI;
import org.gradle.api.DefaultTask;
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputFile;
import org.gradle.api.tasks.InputFiles;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

/**
 * A gradle task to invoke the OmlConvert tool 
 */
public abstract class OmlConvertTask extends DefaultTask {

	/**
	 * Creates a new OmlConvertTask object
	 */
	public OmlConvertTask() {
	}

	/**
	 * The path to an input OML catalog
	 * 
	 * @return File Property
	 */
	@InputFile
    public abstract Property<File> getInputCatalogPath();

	/**
	 * The path to an output OML catalog
	 * 
	 * @return File Property
	 */
	@InputFile
    public abstract Property<File> getOutputCatalogPath();

	/**
	 * The extension for the output OML files (options: oml, omlxmi, omljson)
	 * 
	 * @return String Property
	 */
    @Input
    public abstract Property<String> getOutputFileExtension();

	/**
	 * Whether to use the catalog to resolve cross references (default: true, only relevant when output file extension is omlxmi or omljson)
	 * 
	 * @return Boolean Property
	 */
    @Input
    public abstract Property<Boolean> getUseCatalog();
    
	/**
	 * The debug flag
	 * 
	 * @return Boolean Property
	 */
    @Input
    @Optional
    public abstract Property<Boolean> getDebug();

	/**
	 * The collection of input OML files referenced by the input OML catalog
	 * 
	 * @return ConfigurableFileCollection
     * @throws IOException error
	 */
    @Incremental
    @InputFiles
    protected ConfigurableFileCollection getInputFiles() throws IOException {
		if (getInputCatalogPath().isPresent()) {
			String s = getInputCatalogPath().get().getAbsolutePath();
    		final URI inputCatalogURI = URI.createFileURI(s);
    		Collection<File> files = OmlConvertApp.collectOMLFiles(inputCatalogURI);
    		files.add(getInputCatalogPath().get());
    		return getProject().files(files);
		}
		return getProject().files(Collections.EMPTY_LIST);
   }

    /**
     * The gradle task action logic.
     */
    @TaskAction
    public void run() {
		List<String> args = new ArrayList<>();
		if (getInputCatalogPath().isPresent()) {
			args.add("-i");
			args.add(getInputCatalogPath().get().getAbsolutePath());
		}
		if (getOutputCatalogPath().isPresent()) {
			args.add("-o");
			args.add(getOutputCatalogPath().get().getAbsolutePath());
		}
		if (getOutputFileExtension().isPresent()) {
			args.add("-f");
			args.add(getOutputFileExtension().get());
		}
		if (getUseCatalog().isPresent()) {
			args.add("-u");
			args.add(getUseCatalog().get().toString());
		}
		if (getDebug().isPresent() && getDebug().get()) {
			args.add("-d");
		}
		try {
    		OmlConvertApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}