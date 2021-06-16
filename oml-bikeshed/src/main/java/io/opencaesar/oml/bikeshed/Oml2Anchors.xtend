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

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet

import static extension io.opencaesar.oml.util.OmlRead.*

class Oml2Anchors {

	val URI anchorsFileURI
	val ResourceSet inputResourceSet
	
	new(URI anchorsFileURI, ResourceSet inputResourceSet) {
		this.anchorsFileURI = anchorsFileURI
		this.inputResourceSet = inputResourceSet
	}
	
	def String run() '''
		«FOR ontology : inputResourceSet.ontologies»
			«val relativePath = ontology.eResource.URI.deresolve(anchorsFileURI, true, true, false).toString»
			«val baseRelativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))»
			«IF !ontology.members.empty»
			urlPrefix: «baseRelativePath».html#; type: dfn; spec: «ontology.iri»
				«FOR member: ontology.members»
				text: «member.name»
				«ENDFOR»
			«ENDIF»
			
		«ENDFOR»

	'''
	
}