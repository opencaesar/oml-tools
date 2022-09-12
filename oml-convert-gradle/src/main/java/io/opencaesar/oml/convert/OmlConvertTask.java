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

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.file.DirectoryProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputDirectory;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

public abstract class OmlConvertTask extends DefaultTask {
	
    @Incremental
    @InputDirectory
    public abstract DirectoryProperty getRootFolder();
    
    @Input
    public abstract Property<String> getInputPattern();

    @Input
    public abstract Property<String> getOutputExtension();
    
    @Input
    public abstract Property<Boolean> getUseCatalog();

    @Optional
    @Input
    public abstract Property<Boolean> getDeleteInputs();

    @TaskAction
    public void run() {
		List<String> args = new ArrayList<>();
		if (getRootFolder().isPresent()) {
			args.add("-r");
			args.add(getRootFolder().get().getAsFile().getAbsolutePath());
		}
		if (getInputPattern().isPresent()) {
			args.add("-i");
			args.add(getInputPattern().get());
		}
		if (getOutputExtension().isPresent()) {
			args.add("-o");
			args.add(getOutputExtension().get());
		}
		if (getUseCatalog().isPresent()) {
			args.add("-u");
			args.add(getUseCatalog().get().toString());
		}
		if (getDeleteInputs().isPresent()) {
			if (getDeleteInputs().get()) {
				args.add("-d");
			}
		}
		try {
    		OmlConvertApp.main(args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}