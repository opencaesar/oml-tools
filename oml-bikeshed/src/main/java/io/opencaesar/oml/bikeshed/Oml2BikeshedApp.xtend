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
package io.opencaesar.oml.bikeshed

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.JCommander
import com.beust.jcommander.Parameter
import com.beust.jcommander.ParameterException
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.dsl.OmlStandaloneSetup
import io.opencaesar.oml.util.OmlCatalog
import io.opencaesar.oml.util.OmlConstants
import io.opencaesar.oml.validate.OmlValidator
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.util.ArrayList
import java.util.Arrays
import java.util.Collection
import java.util.Collections
import java.util.HashMap
import java.util.LinkedHashMap
import java.util.List
import org.apache.log4j.AppenderSkeleton
import org.apache.log4j.Level
import org.apache.log4j.LogManager
import org.apache.log4j.xml.DOMConfigurator
import org.apache.xml.resolver.Catalog
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.util.ECrossReferenceAdapter

import static extension io.opencaesar.oml.util.OmlRead.*

class Oml2BikeshedApp {

	@Parameter(
		names=#["--input-catalog-path","-i"], 
		description="Path of OML input catalog (Required)",
		validateWith=InputCatalogPath, 
		required=true, 
		order=1
	)
	String inputCatalogPath = null

	@Parameter(
		names=#["--input-catalog-title", "-it"], 
		description="Title of OML input catalog (Optional)", 
		required=false, 
		order=2
	)
	String inputCatalogTitle

	@Parameter(
		names=#["--input-catalog-version", "-iv"], 
		description="Version of OML input catalog (Optional)", 
		required=false, 
		order=3
	)
	String inputCatalogVersion

	@Parameter(
		names=#["--root-ontology-iri","-r"], 
		description="Root OML ontology IRI (Required)",
		required=false, 
		order=4
	)
	String rootOntologyIri = null

	@Parameter(
		names=#["--output-folder-path", "-o"], 
		description="Path of Bikeshed output folder", 
		validateWith=OutputFolderPath, 
		required=true, 
		order=5
	)
	String outputFolderPath = "."

	@Parameter(
		names=#["--publish-url", "-u"], 
		description="URL where the Bikeshed documentation will be published", 
		required=true, 
		order=6
	)
	String publishUrl

	@Parameter(
		names=#["--force","-f"], 
		description="Run bikeshed with force option -f", 
		help=true, 
		order=7
	)
	boolean force
		
	@Parameter(
		names=#["-debug", "--d"], 
		description="Shows debug logging statements", 
		order=8
	)
	boolean debug

	@Parameter(
		names=#["--help","-h"], 
		description="Displays summary of options", 
		help=true, 
		order=9
	)
	boolean help

	@Parameter(
		names=#["--version","-v"], 
		description="Displays app version", 
		help=true, 
		order=10
	)
	boolean version
	
	val LOGGER = LogManager.getLogger(Oml2BikeshedApp)
	
	val logoString = '''<a href="http://www.opencaesar.io/oml/" class="logo"><img alt="OML Specification" height="48" src="https://opencaesar.github.io/oml/images/oml.svg"></a>'''

	/**
	 * Main method
	 * 
	 * @param args command line arguments for the app
	 */
	def static void main(String ... args) {
		val app = new Oml2BikeshedApp
		val builder = JCommander.newBuilder().addObject(app).build()
		builder.parse(args)
		if (app.version) {
			println(app.getAppVersion)
			return
		}
		if (app.help) {
			builder.usage()
			return
		}
        DOMConfigurator.configure(ClassLoader.getSystemClassLoader().getResource("log4j.xml"))
		if (app.debug) {
			val appender = LogManager.getRootLogger.getAppender("stdout")
			(appender as AppenderSkeleton).setThreshold(Level.DEBUG)
		}
		if (app.outputFolderPath.endsWith(File.separator)) {
			app.outputFolderPath = app.outputFolderPath.substring(0, app.outputFolderPath.length-1)
		}
		app.run()
	}

	/*
	 * Run method
	 */
	def void run() {
		LOGGER.info("=================================================================")
		LOGGER.info("                        S T A R T")
		LOGGER.info("                    OML to Bikeshed "+getAppVersion)
		LOGGER.info("=================================================================")
		LOGGER.info("Input Catalog= " + inputCatalogPath)
		LOGGER.info("Root Ontology= " + rootOntologyIri)
		LOGGER.info("Output Folder= " + outputFolderPath)
		
		val inputCatalogFile = new File(inputCatalogPath)
        val inputCatalog = OmlCatalog.create(URI.createFileURI(inputCatalogFile.toString))
		
		OmlStandaloneSetup.doSetup
		val inputResourceSet = new ResourceSetImpl
		inputResourceSet.eAdapters.add(new ECrossReferenceAdapter)
		
		var List<Ontology> inputOntologies = new ArrayList<Ontology> 
		if (rootOntologyIri !== null) {
			var rootUri = resolveRootOntologyIri(rootOntologyIri, inputCatalog)
			val rootOntology = inputResourceSet.getResource(rootUri, true).contents.filter(Ontology).head
			inputOntologies += (#[rootOntology] + rootOntology.allImports.map[importedOntology]).toSet.sortBy[iri]
		} else {
			val omlFiles = collectOmlFiles(inputCatalog)
			for (omlFile : omlFiles) {
				val ontologyUri = URI.createFileURI(omlFile.absolutePath)
				var ontology = inputResourceSet.getResource(ontologyUri, true).contents.filter(Ontology).head
				inputOntologies += ontology  
			}
			inputOntologies = inputOntologies.sortBy[iri]
		}

		val context = new OmlSearchContext(inputOntologies)
		
		// validate ontologies
		for (ontology : inputOntologies) {
			OmlValidator.validate(ontology);
		}

		val outputFiles = new HashMap<File, String>

		// create the script file
		val scriptContents = new StringBuffer
		val forceToken=if(force) "-f" else "--die-on=link-error"
		scriptContents.append('''
			bikeshed «forceToken» spec index.bs
		''')
		for (ontology : inputOntologies) {
		    val uri = URI.createURI(ontology.iri)
			val relativePath = uri.authority+uri.path
			scriptContents.append('''
				bikeshed «forceToken» spec «relativePath».bs
			''')
		}
		val publishShFile = new File(outputFolderPath+File.separator+'publish.sh').canonicalFile
		outputFiles.put(publishShFile, '''
			#!/bin/sh
			cd "$(dirname "$0")"
			«scriptContents»
		''')
		val publishBatFile = new File(outputFolderPath+File.separator+'publish.bat').canonicalFile
		outputFiles.put(publishBatFile, '''
			pushd "%~dp0"
			«scriptContents»
			popd
		''')

		// create the index file as bikeshed spec
		val indexFile = new File(outputFolderPath+File.separator+'index.bs')
		val indexContents = new StringBuffer
		indexContents.append(Oml2Index.addHeader(publishUrl, inputCatalogTitle, inputCatalogVersion))
		var index = 1
		
		val groupsByDomain = new LinkedHashMap<String, Oml2Index.Group>
        for (ontology : inputOntologies) {
            val uri = URI.createURI(ontology.iri)
            val relativePath = uri.authority+uri.path
			val oml2index = new Oml2Index(ontology, context, relativePath, index++)
			groupsByDomain.computeIfAbsent(oml2index.domain, [new Oml2Index.Group]).add(oml2index)
		}
		
		for (group : groupsByDomain.values) {
			indexContents.append(group.run)
		}
		
		indexContents.append(Oml2Index.addFooter)
		outputFiles.put(indexFile, indexContents.toString)
		outputFiles.put(new File(outputFolderPath+File.separator+'logo.include'), logoString)
		
		// create the anchors.bsdata files
		val relativePaths = inputOntologies.map[URI.createURI(iri).trimSegments(1)].map[authority+path].toSet
		for (relativePath : relativePaths) {
            var anchors = new Oml2Anchors(outputFolderPath, relativePath, inputOntologies).run
			outputFiles.put(new File(outputFolderPath+File.separator+relativePath+File.separator+'anchors.bsdata'), anchors)
			// this may write the same logo file multiple times
			outputFiles.put(new File(outputFolderPath+File.separator+relativePath+File.separator+'logo.include'), logoString)
		}

		// create the ontology files
        for (ontology : inputOntologies) {
            val uri = URI.createURI(ontology.iri)
            val relativePath = uri.authority+uri.path
			val bikeshedFile = new File(outputFolderPath+File.separator+relativePath+'.bs')
			outputFiles.put(bikeshedFile, new Oml2Bikeshed(ontology, context, publishUrl, relativePath).run)
		}

		// save output files				
		outputFiles.forEach[file, result|
			file.parentFile.mkdirs
			val filePath = file.canonicalPath
			val out = new BufferedWriter(new FileWriter(filePath))
	
			try {
				LOGGER.info("Saving: "+filePath)
			    out.write(result.toString) 
			}
			catch (IOException e) {
			    System.out.println(e)
			}
			finally {
			    out.close()
			}
		]
		
		publishShFile.setExecutable(true)
		
		LOGGER.info("=================================================================")
		LOGGER.info("                          E N D")
		LOGGER.info("=================================================================")
	}
	
	// Utility methods

	def static Collection<File> collectOmlFiles(OmlCatalog catalog) {
		val files = new ArrayList<File>
		for (entry : catalog.entries.filter[entryType == Catalog.REWRITE_URI]) {
			val folderPath = entry.getEntryArg(1)
			val folder = new File(URI.createURI(folderPath).toFileString)
			files.addAll(collectOmlFiles(folder))
		}
		for (subCatalogPath : catalog.nestedCatalogs) {
			val subCatalog = OmlCatalog.create(URI.createFileURI(subCatalogPath))
			files.addAll(collectOmlFiles(subCatalog))
		}
		return files
	}
	
	def static List<File> collectOmlFiles(File path) {
		val files = if (path.isDirectory()) {
			Arrays.asList(path.listFiles())
		} else {
			Collections.singletonList(path)
		}
		val omlFiles = new ArrayList<File>
		for (file : files) {
			if (file.isDirectory) {
				omlFiles.addAll(collectOmlFiles(file))
			} else if (file.isFile) {
				val ext = getFileExtension(file)
				if (OmlConstants.OML_EXTENSIONS.contains(ext)) {
					omlFiles.add(file)
				}
			} else { // must be a file name with no extension
				for (String ext : OmlConstants.OML_EXTENSIONS) {
					val f = new File(path.toString()+'.'+ext)
					if (f.exists()) {
						omlFiles.add(f)
					}
				}
			}
		}
		return omlFiles
	}

	static def URI resolveRootOntologyIri(String rootOntologyIri, OmlCatalog catalog) {
		val resolved = URI.createURI(catalog.resolveURI(rootOntologyIri))
		
		if (resolved.file) {
			val filename = resolved.toFileString
			if (new File(filename).isFile) {
				return resolved
			}
			for (String ext : OmlConstants.OML_EXTENSIONS) {
				if (new File(filename+'.'+ext).isFile) {
					return URI.createFileURI(filename+'.'+ext)
				}
			}
		}
		
		return resolved
	}

	private static def String getFileExtension(File file) {
        val fileName = file.getName()
        if(fileName.lastIndexOf(".") != -1)
        	return fileName.substring(fileName.lastIndexOf(".")+1)
        else 
        	return ""
    }

	static class InputCatalogPath implements IParameterValidator {
		override validate(String name, String value) throws ParameterException {
			val file = new File(value)
			if (!file.getName().endsWith("catalog.xml")) {
				throw new ParameterException("Parameter " + name + " should be a valid OML catalog path")
			}
	  	}
	}

	static class OutputFolderPath implements IParameterValidator {
		override validate(String name, String value) throws ParameterException {
			val directory = new File(value).absoluteFile
			if (!directory.isDirectory) {
				val created = directory.mkdirs
				if (!created) {
					throw new ParameterException("Parameter " + name + " should be a valid folder path")
				}
			}
	  	}
	}
	
	/**
	 * Get application version id from properties file.
	 * @return version string from build.properties or UNKNOWN
	 */
	def String getAppVersion() {
    	var version = this.getClass().getPackage().getImplementationVersion();
    	return (version !== null) ? version : "<SNAPSHOT>";
	}
	
}
