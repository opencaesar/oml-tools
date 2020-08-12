package io.opencaesar.oml.merge;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.apache.log4j.Appender;
import org.apache.log4j.AppenderSkeleton;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.resource.XtextResourceSet;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;
import com.google.common.io.CharStreams;

import io.opencaesar.oml.dsl.OmlStandaloneSetup;
import io.opencaesar.oml.util.OmlCatalog;
import io.opencaesar.oml.util.OmlXMIResourceFactory;

public class OmlMergeApp {

	@Parameter(
		names = { "--input-catalog-path", "-i" },
		description = "Paths to OML input catalog files (Required)",
		validateWith = InputCatalogPath.class,
		required = true,
		order = 1)
	private List<String> inputCatalogPaths = null;

	@Parameter(
			names = { "--output-catalog-path", "-o" },
			description = "Paths to OML output catalog files (Required)",
			validateWith = OutputCatalogPath.class,
			required = true,
			order = 1)
	private String outputCatalogPath = null;

	@Parameter(
		names = { "-d", "--debug" },
		description = "Shows debug logging statements",
		order = 4)
	private boolean debug;

	@Parameter(
		names = { "--help", "-h" },
		description = "Displays summary of options",
		help = true,
		order =5)
	private boolean help;
	
	private final Logger LOGGER = Logger.getLogger(OmlMergeApp.class);

	public static void main(final String... args) throws Exception {
		final OmlMergeApp app = new OmlMergeApp();
		final JCommander builder = JCommander.newBuilder().addObject(app).build();
		builder.parse(args);
		if (app.help) {
			builder.usage();
			return;
		}
        DOMConfigurator.configure(ClassLoader.getSystemClassLoader().getResource("log4j.xml"));
		if (app.debug) {
			final Appender appender = Logger.getRootLogger().getAppender("stdout");
			((AppenderSkeleton) appender).setThreshold(Level.DEBUG);
		}
		app.run();
	}

	public void run() throws Exception {
		LOGGER.info("=================================================================");
		LOGGER.info("                        S T A R T");
		LOGGER.info("                       OML Merge " + getAppVersion());
		LOGGER.info("=================================================================");
		LOGGER.info(("Input Catalogs = [" + String.join(", ", inputCatalogPaths))+"]");
		LOGGER.info(("Output Catalogs = [" + String.join(", ", outputCatalogPath))+"]");

		// create resource set
		OmlStandaloneSetup.doSetup();
		OmlXMIResourceFactory.register();
		XtextResourceSet resourceSet = new XtextResourceSet();

		// Create output OML Catalog
		LOGGER.info("Saving: "+outputCatalogPath);
		File outputCatalogFile = new File(outputCatalogPath);
		outputCatalogFile.getParentFile().mkdirs();
		BufferedWriter bw = new BufferedWriter(new FileWriter(outputCatalogFile));
		bw.write(
			"<?xml version='1.0'?>\n"+
			"<catalog xmlns=\"urn:oasis:names:tc:entity:xmlns:xml:catalog\" prefer=\"public\">\n" +
			"\t<rewriteURI uriStartString=\"http://\" rewritePrefix=\"./\" />\n" +
			"</catalog>"
		);	
		bw.close();
		OmlCatalog catalog = OmlCatalog.create(new URL("file:"+outputCatalogPath));

		// Create the OML merger
		Collection<String> errors = new ArrayList<String>();
		OmlMerger merger = new OmlMerger(resourceSet, catalog, errors);
		

		// Merge the input OML catalogs
		merger.start();
		for (String inputCatalogPath : inputCatalogPaths) {
			File inputCatalogFile = new File(inputCatalogPath);
			File inputFolder = inputCatalogFile.getParentFile();
			Collection<File> inputFiles = collectOMLFiles(inputFolder);
						
			// Merge the input OML resource
			for (File inputFile : inputFiles) {
				URI inputURI = URI.createFileURI(inputFile.getAbsolutePath());
				LOGGER.info("Reading: "+inputURI);
				Resource inputResource = resourceSet.getResource(inputURI, true);
				merger.merge(inputResource);
			}
			
			// run all deferred tasks
			merger.finish();
		}

		// Check errors
		if (errors.isEmpty()) {
			// Save the output OML resources
			for (Resource resource : merger.getMergedResources()) {
				LOGGER.info("Saving "+resource.getURI());
				resource.save(Collections.emptyMap());
			}
		} else {
			for (String error : errors) {
				LOGGER.error(error);
			}
			System.exit(-1);
		}
		
		
		LOGGER.info("=================================================================");
		LOGGER.info("                          E N D");
		LOGGER.info("=================================================================");
	}

	public Collection<File> collectOMLFiles(File directory) {
		List<File> omlFiles = new ArrayList<File>();
		for (File file : directory.listFiles()) {
			if (file.isFile()) {
				String ext = getFileExtension(file);
				if (ext.equals(OmlMerger.OML) || ext.equals(OmlMerger.OMLXMI)) {
					omlFiles.add(file);
				}
			} else if (file.isDirectory()) {
				omlFiles.addAll(collectOMLFiles(file));
			}
		}
		return omlFiles;
	}

	private String getFileExtension(File file) {
        String fileName = file.getName();
        if(fileName.lastIndexOf(".") != -1)
        	return fileName.substring(fileName.lastIndexOf(".")+1);
        else 
        	return "";
    }

	/**
	 * Get application version id from properties file.
	 * 
	 * @return version string from build.properties or UNKNOWN
	 */
	public String getAppVersion() {
		String version = "UNKNOWN";
		try {
			InputStream input = Thread.currentThread().getContextClassLoader().getResourceAsStream("version.txt");
			InputStreamReader reader = new InputStreamReader(input);
			version = CharStreams.toString(reader);
		} catch (IOException e) {
			String errorMsg = "Could not read version.txt file." + e;
			LOGGER.error(errorMsg, e);
		}
		return version;
	}

	public static class InputCatalogPath implements IParameterValidator {
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			File file = new File(value);
			if (!file.getName().endsWith("catalog.xml") || !file.exists()) {
				throw new ParameterException("Parameter " + name + " should be an existing catalog.xml path");
			}
		}
	}

	public static class OutputCatalogPath implements IParameterValidator {
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			File file = new File(value);
			if (!file.getName().endsWith("catalog.xml")) {
				throw new ParameterException("Parameter " + name + " should be a valid catalog.xml path");
			}
		}
	}

	public static class OutputFilePath implements IParameterValidator {
		@Override
		public void validate(final String name, final String value) throws ParameterException {
			File folder = new File(value).getParentFile();
			if (!folder.exists()) {
				folder.mkdir();
			}
		}
	}

}
