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
import java.util.HashSet
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

class Oml2BikeshedApp {
	
	@Parameter(
		names=#["--input-path","-i"], 
		description="Location of Oml input folder (Required)",
		validateWith=FolderPath, 
		required=true, 
		order=1)
	package String inputPath = null

	@Parameter(
		names=#["--output-path", "-o"], 
		description="Location of the Bikeshed output folder", 
		required=true, 
		order=2
	)
	package String outputPath = "."

	@Parameter(
		names=#["--url", "-u"], 
		description="Base URL where the Bikeshed documentation will be published", 
		required=true, 
		order=3
	)
	package String url

	@Parameter(
		names=#["-debug", "--d"], 
		description="Shows debug logging statements", 
		order=4
	)
	package boolean debug

	@Parameter(
		names=#["--help","-h"], 
		description="Displays summary of options", 
		help=true, 
		order=5)
	package boolean help

	@Parameter(
		names=#["--version","-v"], 
		description="Displays app version", 
		help=true, 
		order=6)
	package boolean version
	
	@Parameter(
		names=#["--force","-f"], 
		description="Run bikeshed with force option -f", 
		help=true, 
		order=7)
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
		if (app.inputPath.endsWith('/')) {
			app.inputPath = app.inputPath.substring(0, app.inputPath.length-1)
		}
		if (app.outputPath.endsWith('/')) {
			app.outputPath = app.outputPath.substring(0, app.outputPath.length-1)
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
		LOGGER.info("Input Folder= " + inputPath)
		LOGGER.info("Output Folder= " + outputPath)

		val inputFolder = new File(inputPath).canonicalFile
		val inputFiles = collectInputFiles(inputFolder).sortBy[canonicalPath]
		val allInputFolders = new HashSet<File>
		
		OmlStandaloneSetup.doSetup
		val inputResourceSet = new XtextResourceSet
		inputResourceSet.eAdapters.add(new ECrossReferenceAdapter)

		val outputFiles = new HashMap<File, String>

		// load all resources first
		var valid = true
		for (inputFile : inputFiles.sortBy[canonicalPath]) {
			allInputFolders.add(inputFile.getParentFile())
			val inputURI = URI.createFileURI(inputFile.absolutePath)
			LOGGER.info("Reading: "+inputURI)
			val inputResource = inputResourceSet.getResource(inputURI, true)
			if (inputResource !== null) {
				val ontology = inputResource.ontology
				if (!validate(ontology)) {
					valid = false
				}
			}
		}
		if (valid === false) {
			return
		}

		// create the script file
		val scriptFile = new File(outputPath+'/publish.sh').canonicalFile
		val scriptContents = new StringBuffer
		val forceToken=if(force) "-f" else ""
		scriptContents.append('''
			cd "${BASH_SOURCE%/*}/"
		''')
		scriptContents.append('''
			bikeshed «forceToken» spec index.bs
		''')
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			scriptContents.append('''
				bikeshed «forceToken» spec «relativePath».bs
			''')
		}
		outputFiles.put(scriptFile, scriptContents.toString)

		// create the index file as bikeshed spec
		val indexFile = new File(outputPath+'/index.bs')
		val indexContents = new StringBuffer
		indexContents.append(Oml2Index.addHeader(url, inputPath))
		var index = 1
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			indexContents.append(new Oml2Index(inputResource, relativePath, index++).run)
		}
		indexContents.append(Oml2Index.addFooter)
		outputFiles.put(indexFile, indexContents.toString)
		outputFiles.put(new File(outputPath+'/logo.include'), logoString)
		
		// create the anchors.bsdata files
		for (folder : allInputFolders) {
			val relativePath = inputFolder.toURI().relativize(folder.toURI()).getPath()
			val anchoreResourceURI = URI.createURI(inputFolder.toURI+'/'+relativePath+'/anchors.bsdata') 
			val anchorsFile = new File(outputPath+'/'+relativePath+'/anchors.bsdata')
			outputFiles.put(anchorsFile, new Oml2Anchors(anchoreResourceURI, inputResourceSet).run)
			// this may write the same logo file multiple times
			outputFiles.put(new File(outputPath+'/'+relativePath+'/logo.include'), logoString)
		}

		// create the ontology files
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			val bikeshedFile = new File(outputPath+'/'+relativePath+'.bs')
			outputFiles.put(bikeshedFile, new Oml2Bikeshed(inputResource, url, relativePath).run)
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

	private def String getFileExtension(File file) {
        val fileName = file.getName()
        if(fileName.lastIndexOf(".") != -1)
        	return fileName.substring(fileName.lastIndexOf(".")+1)
        else 
        	return ""
    }

	static class FolderPath implements IParameterValidator {
		override validate(String name, String value) throws ParameterException {
			val directory = new File(value).absoluteFile
			if (!directory.isDirectory) {
				throw new ParameterException("Parameter " + name + " should be a valid folder path")
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
