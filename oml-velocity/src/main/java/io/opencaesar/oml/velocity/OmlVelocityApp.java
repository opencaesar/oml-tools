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

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.FileVisitResult;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.PathMatcher;
import java.nio.file.Paths;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Appender;
import org.apache.log4j.AppenderSkeleton;
import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;

/**
 * An application to generate OML models from Velocity templates  
 */
public class OmlVelocityApp {

	@Parameter(
		names= {"--template-folder","-t"}, 
		description="Path to an OML template folder (Required)",
		validateWith=InputFolderPath.class, 
		required=true, 
		order=1
	)
	private String templateFolderPath;

	@Parameter(
		names= {"--template-include","-i"}, 
		description="A (glob) pattern matching the template files to include (Optional, default: **/*.oml)",
		required=false, 
		order=2
	)
	private String templateInclude = "**/*.oml";

	@Parameter(
		names= {"--template-rename","-r"}, 
		description="A string old:new to find and replace in a template name (Optional)",
		required=false, 
		order=3
	)
	private String templateRename;

	@Parameter(
		names= {"--template-key-value","-k"}, 
		description="Key=value pair to pass as a context when instantiating templates (Optional)",
		required=false, 
		order=4
	)
	private List<String> templateKeyValues = new ArrayList<>();

	@Parameter(
		names= {"--output-folder", "-o"}, 
		description="Path to an output folder for template instantiations (Required)", 
		validateWith=OutputFolderPath.class, 
		required=true, 
		order=5
	)
	private String outputFolderPath;
		
	@Parameter(
		names= {"-debug", "--d"}, 
		description="Shows debug logging statements", 
		order=6
	)
	private boolean debug;

	@Parameter(
		names= {"--help","-h"}, 
		description="Displays summary of options", 
		help=true, 
		order=7
	)
	private boolean help;

	@Parameter(
		names= {"--version","-v"}, 
		description="Displays app version", 
		help=true, 
		order=8
	)
	private boolean version;
	
	private Logger LOGGER = LogManager.getLogger(OmlVelocityApp.class);
	
	/**
	 * Main method
	 * 
	 * @param args command line arguments for the app
	 * @throws Exception when template instantiation has a problem
	 */
	public static void main(String ... args) throws Exception {
		final OmlVelocityApp app = new OmlVelocityApp();
		final JCommander builder = JCommander.newBuilder().addObject(app).build();
		builder.parse(args);
		if (app.version) {
			System.out.println(app.getAppVersion());
			return;
		}
		if (app.help) {
			builder.usage();
			return;
		}
        DOMConfigurator.configure(ClassLoader.getSystemClassLoader().getResource("log4j.xml"));
		if (app.debug) {
			Appender appender = LogManager.getRootLogger().getAppender("stdout");
			((AppenderSkeleton)appender).setThreshold(Level.DEBUG);
		}
		app.run();
	}

	/**
	 * Creates a new OmlVelocityApp object
	 */
	public OmlVelocityApp() {
	}
	
	/**
	 * Run method
	 * 
	 * @throws Exception error
	 */
	public void run() throws Exception {
		LOGGER.info("=================================================================");
		LOGGER.info("                        S T A R T");
		LOGGER.info("                    OML Velocity "+getAppVersion());
		LOGGER.info("=================================================================");
		LOGGER.info("Template folder = " + templateFolderPath);
		LOGGER.info("Template pattern = " + templateInclude);
		LOGGER.info("Template rename = " + templateRename);
		LOGGER.info("Template key value(s) = " + templateKeyValues);
		LOGGER.info("Output folder = " + outputFolderPath);
		
        VelocityEngine velocity = new VelocityEngine();
		velocity.init();
		
		final var inputBasePath = Path.of(templateFolderPath);
		final var outputBasePath = Path.of(outputFolderPath);
        final var templatePaths = collectTemplatePaths(templateFolderPath, templateInclude);
		
		for (Path templatePath : templatePaths) {
			var templateFile = templatePath.toFile();
			var templateReader = new FileReader(templateFile); 
					
			var outputPath = outputBasePath.resolve(inputBasePath.relativize(templatePath));
            var outputFile = outputPath.toFile();
            if (templateRename != null) {
            	String[] s = templateRename.split(":");
            	String parentName = outputFile.getParent();
            	String fileName = outputFile.getName();
            	fileName = fileName.replace(s[0], s[1]);
            	outputFile = new File(parentName+File.separator+fileName);
            }
            outputFile.getParentFile().mkdirs();
            FileWriter outputWriter = new FileWriter(outputFile); 
            
            var context = new VelocityContext();
            for (String templateKeyValue : templateKeyValues) {
            	String[] s = templateKeyValue.split("=");
            	context.put(s[0], s[1]);
            }
            
            System.out.println("Generating "+outputFile);
            
            // Perform template expansion
            if (!velocity.evaluate(context, outputWriter, templateFile.getName(), templateReader)) {
                // Generally Velocity itself throws an exception if there is an error in the template.
                throw new RuntimeException("Failed to instantiate template: "+templateFile);
            }
            
            outputWriter.close();
		}
		
		LOGGER.info("=================================================================");
		LOGGER.info("                          E N D");
		LOGGER.info("=================================================================");
	}
	
	// Utility methods

	private List<Path> collectTemplatePaths(String location, String pattern) throws Exception {
		final var files = new ArrayList<Path>();
		final PathMatcher pathMatcher = FileSystems.getDefault().getPathMatcher("glob:"+pattern);
		Files.walkFileTree(Paths.get(location), new SimpleFileVisitor<Path>() {

			@Override
			public FileVisitResult visitFile(Path path, BasicFileAttributes attrs) throws IOException {
				if (pathMatcher.matches(path)) {
					files.add(path);
				}
				return FileVisitResult.CONTINUE;
			}

			@Override
			public FileVisitResult visitFileFailed(Path file, IOException exc) throws IOException {
				return FileVisitResult.CONTINUE;
			}
		});
		return files;
	}
	
    /**
     * The validator of the input folder path 
     */
	public static class InputFolderPath implements IParameterValidator {
    	/**
    	 * Creates a new InputFolderPath object
    	 */
    	public InputFolderPath() {
    	}
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			final File directory = new File(value).getAbsoluteFile();
			if (!directory.isDirectory()) {
				throw new ParameterException("Parameter "+name+" should be a valid folder path: "+directory);
			}
		}
	}

    /**
     * The validator of the output folder path 
     */
	public static class OutputFolderPath implements IParameterValidator {
    	/**
    	 * Creates a new OutputFolderPath object
    	 */
    	public OutputFolderPath() {
    	}
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			final File directory = new File(value).getAbsoluteFile();
			if (!directory.isDirectory()) {
				final boolean created = directory.mkdirs();
				if ((!created)) {
					throw new ParameterException((("Parameter " + name) + " should be a valid folder path"));
				}
			}
		}
	}

	/**
	 * Get application version id from properties file.
	 * @return version string from build.properties or UNKNOWN
	 */
    private String getAppVersion() {
    	var version = this.getClass().getPackage().getImplementationVersion();
    	return (version != null) ? version : "<SNAPSHOT>";
    }
	
}
