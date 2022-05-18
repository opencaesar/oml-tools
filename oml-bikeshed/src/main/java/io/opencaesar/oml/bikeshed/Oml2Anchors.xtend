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

import io.opencaesar.oml.Ontology
import java.io.File
import java.util.List
import org.eclipse.emf.common.util.URI

import static extension io.opencaesar.oml.util.OmlRead.*

class Oml2Anchors {

	val String outputFolderPath
	val String anchorFolderRelativePath
	val List<Ontology> allOntologies
	
	new(String outputFolderPath, String anchorFolderRelativePath, List<Ontology> allOntologies) {
		this.outputFolderPath = outputFolderPath
		this.anchorFolderRelativePath = anchorFolderRelativePath
		this.allOntologies = allOntologies
	}
	
	def String run() '''
		«FOR ontology : allOntologies»
		    «val ontologyURI = URI.createURI(ontology.iri)»
	        «val ontologyRelativePath = ontologyURI.authority+ontologyURI.path»
	        «val anchorFolderURI = URI.createFileURI(outputFolderPath+File.separator+anchorFolderRelativePath+"/")»
		    «val htmlFileURI = URI.createFileURI(outputFolderPath+File.separator+ontologyRelativePath+".html")»
			«val urlPrefix = htmlFileURI.deresolve(anchorFolderURI, true, true, true).toString»
			
			«IF !ontology.members.empty»
			urlPrefix: «urlPrefix»#; type: dfn; spec: «ontology.iri»
				«FOR member: ontology.members»
				text: «Oml2Bikeshed.getDfn(member)»
				«ENDFOR»
			«ENDIF»
			
		«ENDFOR»

	'''
	
}