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
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.common.util.URI;
import org.gradle.api.DefaultTask;
import org.gradle.api.GradleException;
import org.gradle.api.file.ConfigurableFileCollection;
import org.gradle.api.file.RegularFileProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.*;
import org.gradle.work.Incremental;

import io.opencaesar.oml.util.OmlCatalog;

public abstract class OmlValidateTask extends DefaultTask {
	
    public String inputCatalogPath;

    public void setInputCatalogPath(String s) {
    	try {
    		inputCatalogPath = s;
    		final OmlCatalog inputCatalog = OmlCatalog.create(URI.createFileURI(s));
    		Collection<File> files = OmlValidateApp.collectOmlFiles(inputCatalog);
    		files.add(new File(s));
    		getInputFiles().from(files);
    	} catch (Exception e) {
			throw new GradleException(e.getLocalizedMessage(), e);
    	}
    }

    @Incremental
    @InputFiles
    public abstract ConfigurableFileCollection getInputFiles();

    @OutputFile
    public abstract RegularFileProperty getOutputReportPath();

    @Input
    @Optional
    public abstract Property<Boolean> getDebug();

    @TaskAction
    public void run() {
		List<String> args = new ArrayList<>();
		if (inputCatalogPath != null) {
			args.add("-i");
			args.add(inputCatalogPath);
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