package io.opencaesar.oml2bikeshed

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet

import static extension io.opencaesar.oml.util.OmlRead.*

class OmlToAnchors {

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