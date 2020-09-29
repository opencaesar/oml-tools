package io.opencaesar.oml.bikeshed

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.JCommander
import com.beust.jcommander.Parameter
import com.beust.jcommander.ParameterException
import com.google.common.io.CharStreams
import io.opencaesar.oml.Member
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.dsl.OmlStandaloneSetup
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.io.InputStreamReader
import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import org.apache.log4j.AppenderSkeleton
import org.apache.log4j.Level
import org.apache.log4j.LogManager
import org.apache.log4j.xml.DOMConfigurator
import org.eclipse.emf.common.util.Diagnostic
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.Diagnostician
import org.eclipse.emf.ecore.util.ECrossReferenceAdapter
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.resource.XtextResourceSet

import static extension io.opencaesar.oml.util.OmlRead.*
import io.opencaesar.oml.util.OmlCatalog
import java.util.LinkedHashMap

class Oml2BikeshedApp {
	
	@Parameter(
		names=#["--input-catalog-path","-i"], 
		description="Path of OML input catalog (Required)",
		validateWith=InputCatalogPath, 
		required=true, 
		order=1)
	package String inputCatalogPath = null

	@Parameter(
		names=#["--root-ontology-iri","-r"], 
		description="Root OML ontology IRI (Required)",
		required=true, 
		order=2)
	package String rootOntologyIri = null

	@Parameter(
		names=#["--output-folder-path", "-o"], 
		description="Path of Bikeshed output folder", 
		validateWith=OutputFolderPath, 
		required=true, 
		order=3
	)
	package String outputFolderPath = "."

	@Parameter(
		names=#["--publish-url", "-u"], 
		description="URL where the Bikeshed documentation will be published", 
		required=true, 
		order=4
	)
	package String publishUrl

	@Parameter(
		names=#["-debug", "--d"], 
		description="Shows debug logging statements", 
		order=5
	)
	package boolean debug

	@Parameter(
		names=#["--help","-h"], 
		description="Displays summary of options", 
		help=true, 
		order=6)
	package boolean help

	@Parameter(
		names=#["--version","-v"], 
		description="Displays app version", 
		help=true, 
		order=7)
	package boolean version
	
	@Parameter(
		names=#["--force","-f"], 
		description="Run bikeshed with force option -f", 
		help=true, 
		order=8)
	package boolean force
	
	val LOGGER = LogManager.getLogger(Oml2BikeshedApp)
	
	val logoString = '''<a href="https://www.openapis.org/" class="logo"><img alt="OpenAPI Initiative" height="48" src="https://opencaesar.github.io/oml/images/oml.svg"></a>'''

	/*
	 * Main method
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
		val inputFolder = inputCatalogFile.parentFile
		val inputCatalog = OmlCatalog.create(inputCatalogFile.toURI.toURL)
		
		OmlStandaloneSetup.doSetup
		val inputResourceSet = new XtextResourceSet
		inputResourceSet.eAdapters.add(new ECrossReferenceAdapter)
		
		
		var rootUri = resolveRootOntologyIri(rootOntologyIri, inputCatalog)
		val rootOntology = inputResourceSet.getResource(rootUri, true).contents.filter(Ontology).head
		val inputOntologies = (#[rootOntology] + rootOntology.allImportsWithSource.map[importedOntology]).toSet.sortBy[iri]
		
		val outputFiles = new HashMap<File, String>

		// validate ontologies
		var valid = true
		for (inputOntology : inputOntologies) {
			if (!validate(inputOntology)) {
				valid = false
			}
		}
		if (valid === false) {
			return
		}

		// create the script file
		val scriptFile = new File(outputFolderPath+File.separator+'publish.sh').canonicalFile
		val scriptContents = new StringBuffer
		val forceToken=if(force) "-f " else ""
		scriptContents.append('''
			cd "$(dirname "$0")"
		''')
		scriptContents.append('''
			bikeshed «forceToken»spec index.bs
		''')
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			scriptContents.append('''
				bikeshed «forceToken»spec «relativePath».bs
			''')
		}
		outputFiles.put(scriptFile, scriptContents.toString)

		// create the index file as bikeshed spec
		val indexFile = new File(outputFolderPath+File.separator+'index.bs')
		val indexContents = new StringBuffer
		indexContents.append(Oml2Index.addHeader(publishUrl, Oml2Bikeshed.getCreator(rootOntology), Oml2Bikeshed.getCopyright(rootOntology)))
		var index = 1
		
		val groupsByDomain = new LinkedHashMap<String, Oml2Index.Group>
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			val oml2index = new Oml2Index(inputResource, relativePath, index++)
			groupsByDomain.computeIfAbsent(oml2index.domain, [new Oml2Index.Group]).add(oml2index)
		}
		
		for (group : groupsByDomain.values) {
			indexContents.append(group.run)
		}
		
		indexContents.append(Oml2Index.addFooter)
		outputFiles.put(indexFile, indexContents.toString)
		outputFiles.put(new File(outputFolderPath+File.separator+'logo.include'), logoString)
		
		// create the anchors.bsdata files
		val allInputFolders = inputResourceSet.resources.map[new File(URI.toFileString).parentFile].toSet
		for (folder : allInputFolders) {
			val relativePath = inputFolder.toURI().relativize(folder.toURI()).getPath()
			val anchoreResourceURI = URI.createURI(inputFolder.toURI+File.separator+relativePath+File.separator+'anchors.bsdata') 
			val anchorsFile = new File(outputFolderPath+File.separator+relativePath+File.separator+'anchors.bsdata')
			outputFiles.put(anchorsFile, new Oml2Anchors(anchoreResourceURI, inputResourceSet).run)
			// this may write the same logo file multiple times
			outputFiles.put(new File(outputFolderPath+File.separator+relativePath+File.separator+'logo.include'), logoString)
		}

		// create the ontology files
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			val bikeshedFile = new File(outputFolderPath+File.separator+relativePath+'.bs')
			outputFiles.put(bikeshedFile, new Oml2Bikeshed(inputResource, publishUrl, relativePath).run)
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

		LOGGER.info("=================================================================")
		LOGGER.info("                          E N D")
		LOGGER.info("=================================================================")
	}
	
	def validate(Ontology ontology) {
		val diagnostician = new Diagnostician() {
		  override getObjectLabel(EObject eObject) {
		    val name = if (eObject instanceof Member) {
		    	eObject.abbreviatedIri
		    } else if (eObject instanceof Ontology) {
		    	eObject.iri
		    } else {
		    	EcoreUtil.getID(eObject)
		    }
		    return eObject.eClass.name+' '+name
		  }
		}
		val diagnostic = diagnostician.validate(ontology)
		if (diagnostic.severity === Diagnostic.ERROR) {
			diagnostic.children.forEach[ LOGGER.error(it.message)]
			return false
		}
		return true
	}

	// Utility methods

	def Collection<File> collectInputFiles(File directory) {
		val files = new ArrayList<File>
		for (file : directory.listFiles()) {
			if (file.isFile) {
				val ext = getFileExtension(file)
				if (ext == "oml") {
					files.add(file)
				}
			} else if (file.isDirectory) {
				files.addAll(collectInputFiles(file))
			}
		}
		return files
	}
	
	static def URI resolveRootOntologyIri(String rootOntologyIri, OmlCatalog catalog) {
		val resolved = URI.createURI(catalog.resolveURI(rootOntologyIri))
		
		if (resolved.file) {
			val filename = resolved.toFileString
			if (new File(filename).isFile) {
				return resolved
			}
			if (new File(filename + '.oml').isFile) {
				return URI.createURI(resolved.toString + '.oml')
			}
			if (new File(filename + '.omlxmi').isFile) {
				return URI.createURI(resolved.toString + '.omlxmi')
			}
		}
		
		return resolved
	}

	private def String getFileExtension(File file) {
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
				throw new ParameterException("Parameter " + name + " should be a valid OWL catalog path")
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
		var version = "UNKNOWN"
		try {
			val input = Thread.currentThread().getContextClassLoader().getResourceAsStream("version.txt")
			val reader = new InputStreamReader(input)
			version = CharStreams.toString(reader);
		} catch (IOException e) {
			val errorMsg = "Could not read version.txt file." + e
			LOGGER.error(errorMsg, e)
		}
		version
	}
	
}
