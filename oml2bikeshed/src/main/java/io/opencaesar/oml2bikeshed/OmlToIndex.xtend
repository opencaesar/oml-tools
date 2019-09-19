package io.opencaesar.oml2bikeshed

import java.io.File
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.Oml.*

class OmlToIndex {

	static def String addHeader(String url, String inputPath) '''
		«val inputName = new File(inputPath).name»
		<h1>Documentation of «inputName»</h1>
		
	'''
	
	static def String addFooter() '''
	'''
	
	val Resource inputResource
	val String relativePath
	
	new(Resource inputResource, String relativePath) {
		this.inputResource = inputResource
		this.relativePath = relativePath
	}
	
	def String run() '''
		«val graph = inputResource.graph»
		<p><a href="./«relativePath».html">«graph.iri»</a></p>
	'''
	
}