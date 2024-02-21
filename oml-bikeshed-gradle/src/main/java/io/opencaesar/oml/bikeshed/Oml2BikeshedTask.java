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

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.eclipse.emf.common.util.URI;
import org.gradle.api.DefaultTask;
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.file.DirectoryProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputFile;
import org.gradle.api.tasks.InputFiles;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.OutputDirectory;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

import io.opencaesar.oml.util.OmlCatalog;

/**
 * A gradle task to invoke the Oml2Bikeshed tool 
 */
public abstract class Oml2BikeshedTask extends DefaultTask {

	/**
	 * Creates a new Oml2BikeshedTask object
	 */
	public Oml2BikeshedTask() {
	}
	
	/**
	 * The path to an input OML catalog
	 * 
	 * @return File Property
	 */
	@InputFile
    public abstract Property<File> getInputCatalogPath();

	/**
	 * The title of OML input catalog
	 * 
	 * @return String Property
	 */
    @Optional
    @Input
	public abstract Property<String> getInputCatalogTitle();
	
	/**
	 * The version of OML input catalog
	 * 
	 * @return String Property
	 */
   @Optional
	@Input
	public abstract Property<String> getInputCatalogVersion();
    
	/**
	 * The path of Bikeshed output folder
	 * 
	 * @return Directory Property
	 */
   @OutputDirectory
	public abstract DirectoryProperty getOutputFolderPath();

	/**
	 * The root OML ontology IRI
	 * 
	 * @return String Property
	 */
    @Input
    public abstract Property<String> getRootOntologyIri();
    
	/**
	 * The URL where the Bikeshed documentation will be published
	 * 
	 * @return String Property
	 */
	@Input
    public abstract Property<String> getPublishUrl();

	/**
	 * The debug flag
	 * 
	 * @return Boolean Property
	 */
    @Input
    @Optional
    public abstract Property<Boolean> getDebug();
    
	/**
	 * The collection of input OML files referenced by the OML catalog
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
    		Collection<File> files = Oml2BikeshedApp.collectOmlFiles(inputCatalog);
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
		if (getInputCatalogTitle().isPresent()) {
			args.add("-it");
			args.add(getInputCatalogTitle().get());
		}
		if (getInputCatalogVersion().isPresent()) {
			args.add("-iv");
			args.add(getInputCatalogVersion().get());
		}
		if (getOutputFolderPath().isPresent()) {
			args.add("-o");
			args.add(getOutputFolderPath().get().getAsFile().getAbsolutePath());
		}
		if (getPublishUrl().isPresent()) {
			args.add("-u");
			args.add(getPublishUrl().get());
		}
		if (getRootOntologyIri().isPresent()) {
			args.add("-r");
			args.add(getRootOntologyIri().get());
		}
		if (getDebug().isPresent() && getDebug().get()) {
			args.add("-d");
		}
		try {
    		Oml2BikeshedApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}