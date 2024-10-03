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

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.stream.Collectors;

import org.apache.log4j.Appender;
import org.apache.log4j.AppenderSkeleton;
import org.apache.log4j.Level;
import org.apache.log4j.LogManager;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.ECrossReferenceAdapter;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;

import io.opencaesar.oml.dsl.OmlStandaloneSetup;
import io.opencaesar.oml.resource.OmlJsonResourceFactory;
import io.opencaesar.oml.resource.OmlXMIResourceFactory;
import io.opencaesar.oml.util.OmlRead;
import io.opencaesar.oml.util.OmlResolve;
import io.opencaesar.oml.validate.OmlValidator;

/**
 * An application to convert between the different OML persistence formats 
 */
public class OmlConvertApp {

	@Parameter(
		names = { "--input-catalog-path", "-i" }, 
		description = "Path of the input OML catalog (Required)", 
		validateWith = InputCatalogPath.class, 
		required = true, 
		order = 1)
	private String inputCatalogPath;

	@Parameter(
		names = { "--output-catalog-path", "-o" }, 
		description = "Path of the output OML catalog (Required)", 
		validateWith = OutputCatalogPath.class, 
		required = true, 
		order = 2)
	private String outputCatalogPath;

	@Parameter(
		names = { "--output-file-extension", "-f" },
		description = "Extension for the output OML files (options: oml, omlxmi, omljson)",
		required = true,
		order = 3)
	private OML_EXTENSIONS outputFileExtension;

	enum OML_EXTENSIONS { oml, omlxmi, omljson }
	
	@Parameter(
		names = { "--use-catalog", "-u" },
		description = "Uses the catalog to resolve cross references (default: true, only relevant when output file extension is omlxmi or omljson)",
		required = false,
		arity = 1,
		order = 4)
	private boolean useCatalog = true;
	
	@Parameter(
		names= {"-debug", "--d"}, 
		description="Shows debug logging statements", 
		order=5)
	private boolean debug;

	@Parameter(
		names= {"--help","-h"}, 
		description="Displays summary of options", 
		help=true, 
		order=6)
	private boolean help;

	@Parameter(
		names= {"--version","-v"}, 
		description="Displays app version", 
		help=true, 
		order=7)
	private boolean version;
	
	private Logger LOGGER = LogManager.getLogger(OmlConvertApp.class);
	
	/**
	 * Main method
	 * 
	 * @param args command line arguments for the app
	 * @throws Exception when template instantiation has a problem
	 */
	public static void main(String ... args) throws Exception {
		final OmlConvertApp app = new OmlConvertApp();
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
	 * Creates a new OmlConvertApp object
	 */
	public OmlConvertApp() {
	}
	
	/**
	 * Run method
	 * 
	 * @throws Exception error
	 */
	public void run() throws Exception {
		LOGGER.info("=================================================================");
		LOGGER.info("                        S T A R T");
		LOGGER.info("                    OML Convert "+getAppVersion());
		LOGGER.info("=================================================================");
		LOGGER.info("Input catalog path= " + inputCatalogPath);
		LOGGER.info("Output catalog path= " + outputCatalogPath);
		LOGGER.info("Output file extension= " + outputFileExtension);
		LOGGER.info("Use catalog= " + useCatalog);
		
		OmlStandaloneSetup.doSetup();
		OmlXMIResourceFactory.register(useCatalog);
		OmlJsonResourceFactory.register(useCatalog);
		final var resourceSet = new ResourceSetImpl();
		resourceSet.eAdapters().add(new ECrossReferenceAdapter());
		
		final var inputCatalogUri = URI.createFileURI(inputCatalogPath);

		// load the OML ontologies
		final var inputFiles = collectOMLFiles(inputCatalogUri);
		final var inputResources = new ArrayList<Resource>();
		for (File inputFile : inputFiles) {
			final var inputUri = URI.createFileURI(inputFile.getAbsolutePath());
			LOGGER.info(("Reading: " + inputUri));
			final var inputResource = resourceSet.getResource(inputUri, true);
			inputResources.add(inputResource);
		}
		
		// validate resources
		final StringBuffer problems = new StringBuffer();
		for (var inputResource : inputResources) {
			final var results = OmlValidator.validate(inputResource);
	        if (results.length()>0) {
	        	if (problems.length()>0)
	        		problems.append("\n\n");
	        	problems.append(results);
	        }
		}
		if (problems.length()>0) {
			throw new IllegalStateException("\n"+problems.toString());
		}

		// create the output OML catalog
		final var outputCatalogFile = new File(outputCatalogPath);
		createOutputCatalog(outputCatalogFile);

		// convert the input OML files to the output format
		final var outputFolderPath = outputCatalogFile.getParentFile().getAbsolutePath();
		final var outputResources = new ArrayList<Resource>();
		for (var inputResource : inputResources) {
			final var ontology = OmlRead.getOntology(inputResource);
            final var uri = URI.createURI(ontology.getIri());
            final var relativePath = uri.authority()+uri.path();
			var outputUri = URI.createFileURI(outputFolderPath+File.separator+relativePath+"."+outputFileExtension);
			final Resource outputResource = resourceSet.createResource(outputUri);
			outputResource.getContents().add(ontology);
			outputResources.add(outputResource);
		}

		// save the output OML files
		for (var outputResource : outputResources) {
			LOGGER.info("Saving: "+outputResource.getURI());
			outputResource.save(Collections.EMPTY_MAP);
		}

		LOGGER.info("=================================================================");
		LOGGER.info("                          E N D");
		LOGGER.info("=================================================================");
	}
	
	// Utility methods

	/**
	 * Returns all the OML Files referenced by the passed catalog
	 * 
	 * @param inputCatalogURI the URI of the Oml catalog
	 * @return Collection of Files
	 * @throws IOException exception thrown
	 */
	public static Collection<File> collectOMLFiles(URI inputCatalogURI) throws IOException  {
		return OmlResolve.resolveOmlFileUris(inputCatalogURI).stream()
			.map(i -> new File(i.toFileString()))
			.collect(Collectors.toList());
	}
	
	private void createOutputCatalog(final File outputCatalogFile) throws Exception {
		LOGGER.info(("Saving: file:" + outputCatalogFile));
		outputCatalogFile.getParentFile().mkdirs();
        BufferedWriter bw = new BufferedWriter(new FileWriter(outputCatalogFile));
        bw.write(
                "<?xml version='1.0'?>\n" +
                        "<catalog xmlns=\"urn:oasis:names:tc:entity:xmlns:xml:catalog\" prefer=\"public\">\n" +
                        "\t<rewriteURI uriStartString=\"http://\" rewritePrefix=\"./\" />\n" +
                        "</catalog>"
        );
        bw.close();
	}

	/**
	 * The validator of input catalog paths
	 */
	public static class InputCatalogPath implements IParameterValidator {
		/**
		 * Creates a new InputCatalogPath object
		 */
		public InputCatalogPath() {
		}
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			final File file = new File(value);
			if (!file.exists() || !file.getName().endsWith("catalog.xml")) {
				throw new ParameterException((("Parameter " + name) + " should be a valid OML catalog path"));
			}
		}
	}

	/**
	 * The validator of output catalog paths
	 */
	public static class OutputCatalogPath implements IParameterValidator {
		/**
		 * Creates a new OutputCatalogPath object
		 */
		public OutputCatalogPath() {
		}
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			final File file = new File(value);
			if (!file.getName().endsWith("catalog.xml")) {
				throw new ParameterException((("Parameter " + name) + " should be a valid OML catalog path"));
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
