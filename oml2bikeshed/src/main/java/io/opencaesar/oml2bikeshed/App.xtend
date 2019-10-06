package io.opencaesar.oml2bikeshed

import com.beust.jcommander.IParameterValidator
import com.beust.jcommander.JCommander
import com.beust.jcommander.Parameter
import com.beust.jcommander.ParameterException
import io.opencaesar.oml.dsl.OmlStandaloneSetup
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import org.apache.log4j.AppenderSkeleton
import org.apache.log4j.Level
import org.apache.log4j.LogManager
import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.emf.ecore.util.ECrossReferenceAdapter
import java.io.PrintStream

class App {
	
	private val logoString = '''
		<a href="https://www.openapis.org/" class="logo"><img alt="OpenAPI Initiative" height="48" src="https://opencaesar.github.io/oml-spec/oml-logo.png"></a>
		'''

	@Parameter(
		names=#["--input","-i"], 
		description="Location of Oml input folder (Required)",
		validateWith=FolderPath, 
		required=true, 
		order=1)
	package String inputPath = null

	@Parameter(
		names=#["--output", "-o"], 
		description="Location of the Bikeshed output folder", 
		validateWith=FolderPath, 
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

	val LOGGER = LogManager.getLogger(App)

	/*
	 * Main method
	 */
	def static void main(String ... args) {
		val app = new App
		val builder = JCommander.newBuilder().addObject(app).build()
		builder.parse(args)
		if (app.help) {
			builder.usage()
			return
		}
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
		LOGGER.info("=================================================================")
		LOGGER.info("Input Folder= " + inputPath)
		LOGGER.info("Output Folder= " + outputPath)

		val inputFolder = new File(inputPath)
		val inputFiles = collectInputFiles(inputFolder).sortBy[canonicalPath]
		val allInputFolders = new HashSet<File>
		
		val injector = new OmlStandaloneSetup().createInjectorAndDoEMFRegistration()
		val inputResourceSet = injector.getInstance(XtextResourceSet)
		inputResourceSet.eAdapters.add(new ECrossReferenceAdapter)

		val outputFiles = new HashMap<File, String>


		// load all resources first
		for (inputFile : inputFiles.sortBy[canonicalPath]) {
			allInputFolders.add(inputFile.getParentFile())
			val inputURI = URI.createFileURI(inputFile.absolutePath)
			val inputResource = inputResourceSet.getResource(inputURI, true)
			if (inputResource !== null) {
				LOGGER.info("Reading: "+inputURI)
			}
		}

		// create the script file
		val scriptFile = new File(outputPath+'/publish.sh')
		val scriptContents = new StringBuffer
		scriptContents.append('''
			bikeshed spec index.bs
		''')
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			scriptContents.append('''
				bikeshed spec «relativePath».bs
			''')
		}
		outputFiles.put(scriptFile, scriptContents.toString)

		// create the index file as bikeshed spec
		val indexFile = new File(outputPath+'/index.bs')
		val indexContents = new StringBuffer
		indexContents.append(OmlToIndex.addHeader(url, inputPath))
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			indexContents.append(new OmlToIndex(inputResource, relativePath).run)
		}
		indexContents.append(OmlToIndex.addFooter)
		outputFiles.put(indexFile, indexContents.toString)
		outputFiles.put(new File(outputPath+'/logo.include'), logoString)
		
		// create the anchors.bsdata files
		for (folder : allInputFolders) {
			val relativePath = inputFolder.toURI().relativize(folder.toURI()).getPath()
			val anchoreResourceURI = URI.createFileURI(inputPath+'/'+relativePath+'/anchors.bsdata') 
			val anchorsFile = new File(outputPath+'/'+relativePath+'/anchors.bsdata')
			outputFiles.put(anchorsFile, new OmlToAnchors(anchoreResourceURI, inputResourceSet).run)
			// this may write the same logo file multiple times
			outputFiles.put(new File(outputPath+'/'+relativePath+'/logo.include'), logoString)
		}

		// create the ontology files
		for (inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]) {
			val inputFile = new File(inputResource.URI.toFileString)
			var relativePath = inputFolder.toURI().relativize(inputFile.toURI()).getPath()
			relativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))
			val bikeshedFile = new File(outputPath+'/'+relativePath+'.bs')
			outputFiles.put(bikeshedFile, new OmlToBikeshed(inputResource, url, relativePath).run)
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
			val directory = new File(value)
			if (!directory.isDirectory) {
				throw new ParameterException("Parameter " + name + " should be a valid folder path")
			}
	  	}
	}
	
	private def writeLogoFile(String path) {
		val fout = new PrintStream(new File(path + "/logo.include"))
		fout.println('''
		<a href="https://www.openapis.org/" class="logo"><img alt="OpenAPI Initiative" height="48" src="https://opencaesar.github.io/oml-spec/oml-logo.png"></a>
		''')
		fout.close
	}
	
	
}
