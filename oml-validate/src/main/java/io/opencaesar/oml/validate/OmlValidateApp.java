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
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.apache.log4j.Appender;
import org.apache.log4j.AppenderSkeleton;
import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.apache.xml.resolver.Catalog;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.ECrossReferenceAdapter;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;

import io.opencaesar.oml.dsl.OmlStandaloneSetup;
import io.opencaesar.oml.util.OmlCatalog;
import io.opencaesar.oml.util.OmlConstants;
import io.opencaesar.oml.util.OmlXMIResourceFactory;

public class OmlValidateApp {

	private static final List<String> omlExtensions = Arrays.asList(OmlConstants.OML_EXTENSIONS);
	
	@Parameter(
		names= {"--input-catalog-path", "-i"}, 
		description="Path of OML input catalog (Required)",
		validateWith=InputCatalogPath.class, 
		required=true, 
		order=1)
	private String inputCatalogPath;

	@Parameter(
		names= {"--output-result-path", "-o"}, 
		description="Path of output report file (Optional)", 
		order=2
	)
	private String outputReportPath;

	@Parameter(
		names= {"-debug", "--d"}, 
		description="Shows debug logging statements", 
		order=3
	)
	private boolean debug;

	@Parameter(
		names= {"--help","-h"}, 
		description="Displays summary of options", 
		help=true, 
		order=4)
	private boolean help;

	@Parameter(
		names= {"--version","-v"}, 
		description="Displays app version", 
		help=true, 
		order=5)
	private boolean version;
	
	private Logger LOGGER = LogManager.getLogger(OmlValidateApp.class);
	
	/*
	 * Main method
	 */
	public static void main(String ... args) throws Exception {
		final OmlValidateApp app = new OmlValidateApp();
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

	/*
	 * Run method
	 */
	public void run() throws Exception {
		LOGGER.info("=================================================================");
		LOGGER.info("                        S T A R T");
		LOGGER.info("                    OML Validate "+getAppVersion());
		LOGGER.info("=================================================================");
		LOGGER.info("Input Catalog = " + inputCatalogPath);
		LOGGER.info("Output Report = " + outputReportPath);
		
		// initialize OML resource set
		OmlStandaloneSetup.doSetup();
		OmlXMIResourceFactory.register();
		
		final ResourceSet inputResourceSet = new ResourceSetImpl();
		inputResourceSet.eAdapters().add(new ECrossReferenceAdapter());

		// load the OML catalog
		final OmlCatalog inputCatalog = OmlCatalog.create(URI.createFileURI(inputCatalogPath));

		// validate each resource in turn
		StringBuffer problems = new StringBuffer();
		for(File file : collectOmlFiles(inputCatalog)) {
			URI uri = URI.createFileURI(file.getAbsolutePath());
			Resource r = inputResourceSet.getResource(uri, true);
			String results = OmlValidator.validate(r);
	        if (results.length()>0) {
	        	if (problems.length()>0)
	        		problems.append("\n\n");
	        	problems.append(results);
	        }
		}
		
		if (problems.length() > 0) {
			if (outputReportPath != null) {
				Files.write(Paths.get(outputReportPath), problems.toString().getBytes());
				throw new IllegalStateException("Problems validating OML catalog: check '"+outputReportPath+"' for details.");
			} else {
				throw new IllegalStateException("Problems validating OML catalog:\n"+problems);
			}
		} else {
			// there is no error, delete the report file
			if (outputReportPath != null) {
				File reportFile = new File(outputReportPath);
				if (reportFile.exists()) {
					reportFile.delete();
				}
			}
		}
		
		LOGGER.info("=================================================================");
		LOGGER.info("                          E N D");
		LOGGER.info("=================================================================");
	}
	
	// Utility methods

	public static List<File> collectOmlFiles(OmlCatalog catalog) throws IOException {
		final List<File> files = new ArrayList<>();
		catalog.getEntries().stream().filter(e -> e.getEntryType() == Catalog.REWRITE_URI).forEach(e -> {
			String folderPath = e.getEntryArg(1);
			File path = new File(URI.createURI(folderPath).toFileString());
			files.addAll(collectOmlFiles(path));
		});
		for (String subCatalogPath : catalog.getNestedCatalogs()) {
			final OmlCatalog subCatalog = OmlCatalog.create(URI.createFileURI(subCatalogPath));
			files.addAll(collectOmlFiles(subCatalog));
		}
		return files;
	}
	
	private static List<File> collectOmlFiles(File path) {
		final List<File> files;
		if (path.isDirectory()) {
			files = Arrays.asList(path.listFiles());
		} else {
			files = Collections.singletonList(path);
		}
		final List<File> omlFiles = new ArrayList<>();
		for (File file : files) {
			if (file.isDirectory()) {
				omlFiles.addAll(collectOmlFiles(file));
			} else if (file.isFile()) {
				String ext = getFileExtension(file);
				if (omlExtensions.contains(ext)) {
					omlFiles.add(file);
				}
			} else { // must be a file name with no extension
				for (String ext : omlExtensions) {
					File f = new File(path.toString()+'.'+ext);
					if (f.exists()) {
						omlFiles.add(f);
					}
				}
			}
		}
		return omlFiles;
	}
	
	private static String getFileExtension(File file) {
        String fileName = file.getName();
        if(fileName.lastIndexOf(".") != -1) {
        	return fileName.substring(fileName.lastIndexOf(".")+1);
        } else { 
        	return "";
        }
    }

	public static class InputCatalogPath implements IParameterValidator {
		@Override
		public void validate(String name, String value) throws ParameterException {
			final File file = new File(value);
			if (!file.getName().endsWith("catalog.xml")) {
				throw new ParameterException("Parameter " + name + " should be a valid OML catalog path");
			}
	  	}
	}

	/**
	 * Get application version id from properties file.
	 * @return version string from build.properties or UNKNOWN
	 */
    public String getAppVersion() {
    	var version = this.getClass().getPackage().getImplementationVersion();
    	return (version != null) ? version : "<SNAPSHOT>";
    }
	
}
