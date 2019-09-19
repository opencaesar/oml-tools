package io.opencaesar.oml2bikeshed

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet

import static extension io.opencaesar.oml.Oml.*

class OmlToAnchors {

	val URI anchorsFileURI
	val ResourceSet inputResourceSet
	
	new(URI anchorsFileURI, ResourceSet inputResourceSet) {
		this.anchorsFileURI = anchorsFileURI
		this.inputResourceSet = inputResourceSet
	}
	
	def String run() '''
		«FOR inputResource : inputResourceSet.resources.filter[URI.fileExtension == 'oml'].sortBy[URI.toString]»
			«val relativePath = inputResource.URI.deresolve(anchorsFileURI, true, true, false).toString»
			«val baseRelativePath = relativePath.substring(0, relativePath.lastIndexOf('.'))»
			«val graph = inputResource.graph»
		urlPrefix: «baseRelativePath».html#; type: dfn; spec: «graph.iri»
			«FOR member: graph.members»
			text: «member.name»
			«ENDFOR»
			
		«ENDFOR»

	'''
	
}