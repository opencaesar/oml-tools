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
package io.opencaesar.oml.validate;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.URI;
import org.gradle.api.DefaultTask;
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.file.RegularFileProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputFile;
import org.gradle.api.tasks.InputFiles;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.OutputFile;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

import io.opencaesar.oml.util.OmlCatalog;

/**
 * A gradle task to run the OmlValidate tool 
 */
public abstract class OmlValidateTask extends DefaultTask {

	/**
	 * Creates a new OmlValidateTask object
	 */
	public OmlValidateTask() {
	}
	
	/**
	 * The path of OML input catalog.
	 * 
	 * @return File Property
	 */
    @InputFile
    public abstract Property<File> getInputCatalogPath();

	/**
	 * The path of output report file.
	 * 
	 * @return RegularFile Property
	 */
    @OutputFile
    public abstract RegularFileProperty getOutputReportPath();

	/**
	 * Whether to show debug logging statements.
	 * 
	 * @return Boolean Property
	 */
   @Optional
    @Input
    public abstract Property<Boolean> getDebug();

	/**
	 * The input OML files
	 * 
	 * @return ConfigurableFileCollection
	 * @throws IOException error
	 */
    @Incremental
    @InputFiles
    protected ConfigurableFileCollection getInputFiles() throws IOException {
		if (getInputCatalogPath().isPresent()) {
			String s = getInputCatalogPath().get().getAbsolutePath();
    		final OmlCatalog inputCatalog = OmlCatalog.create(URI.createFileURI(s));
    		Collection<File> files = OmlValidateApp.collectOmlFiles(inputCatalog);
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
		if (getOutputReportPath().isPresent()) {
			args.add("-o");
			args.add(getOutputReportPath().get().getAsFile().getAbsolutePath());
		}
		if (getDebug().isPresent() && getDebug().get()) {
			args.add("-d");
		}
		try {
    		OmlValidateApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}