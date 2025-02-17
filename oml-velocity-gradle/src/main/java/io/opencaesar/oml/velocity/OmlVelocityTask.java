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
package io.opencaesar.oml.velocity;

import java.util.ArrayList;
import java.util.List;

import org.gradle.api.DefaultTask;
import org.gradle.api.file.DirectoryProperty;
import org.gradle.api.provider.ListProperty;
import org.gradle.api.provider.MapProperty;
import org.gradle.api.provider.Property;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputDirectory;
import org.gradle.api.tasks.Optional;
import org.gradle.api.tasks.OutputDirectory;
import org.gradle.api.tasks.TaskAction;
import org.gradle.api.tasks.TaskExecutionException;
import org.gradle.work.Incremental;

/**
 * A gradle task to run the OmlVelocity tool 
 */
public abstract class OmlVelocityTask extends DefaultTask {
	
	/**
	 * Creates a new OmlVelocityTask object
	 */
	public OmlVelocityTask() {
	}
	
	/**
	 * The path to an OML template folder.
	 * 
	 * @return Directory Property
	 */
    @Incremental
    @InputDirectory
    public abstract DirectoryProperty getTemplateFolder();
    
	/**
	 * The (glob) pattern matching the template files to include (default: **\/*.oml).
	 * 
	 * @return String Property
	 */
    @Optional
    @Input
    public abstract Property<String> getTemplateInclude();

	/**
	 * The string old:new to find and replace in a template name.
	 * 
	 * @return String Property
	 */
    @Optional
    @Input
    public abstract Property<String> getTemplateRename();

	/**
	 * The key=value pair to pass as a context when instantiating templates.
	 * 
	 * @return List of String Property
	 */
    @Optional
    @Input
    public abstract ListProperty<String> getTemplateKeyValues();

	/**
	 * A key/value map to pass as a context when instantiating templates.
	 * 
	 * @return List of String Property
	 */
    @Optional
    @Input
    public abstract MapProperty<String, Object> getTemplateKeyValues2();

    /**
	 * The path to an output folder for template instantiations.
	 * 
	 * @return Directory Property
	 */
    @OutputDirectory
    public abstract DirectoryProperty getOutputFolder();
    
    /**
     * The gradle task action logic.
     */
    @TaskAction
    public void run() {
		List<String> args = new ArrayList<>();
		if (getTemplateFolder().isPresent()) {
			args.add("-t");
			args.add(getTemplateFolder().get().getAsFile().getAbsolutePath());
		}
		if (getTemplateInclude().isPresent()) {
			args.add("-i");
			args.add(getTemplateInclude().get());
		}
		if (getTemplateRename().isPresent()) {
			args.add("-r");
			args.add(getTemplateRename().get());
		}
		if (getTemplateKeyValues().isPresent()) {
			for (String templateKeyValue : getTemplateKeyValues().get()) {
				args.add("-k");
				args.add(templateKeyValue);
			}
		}
		if (getOutputFolder().isPresent()) {
			args.add("-o");
			args.add(getOutputFolder().get().getAsFile().getAbsolutePath());
		}
		try {
    		OmlVelocityApp.main(getTemplateKeyValues2().get(), args.toArray(new String[0]));
		} catch (Exception e) {
			throw new TaskExecutionException(this, e);
		}
	}
}