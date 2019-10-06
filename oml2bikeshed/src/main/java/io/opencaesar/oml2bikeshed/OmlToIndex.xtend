package io.opencaesar.oml2bikeshed

import java.io.File
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.Oml.*
import io.opencaesar.oml.NamedElement

/**
 * Generate the index file. We produce this as a bikeshed spec as well in order to 
 * get the bikeshed styling.
 */
class OmlToIndex {

	static def String addHeader(String url, String inputPath) '''
		«val inputName = new File(inputPath).name»
		<pre class='metadata'>
		Title: OML Vocabularies Index
		Shortname: Index
		Level: 1
		Status: LS-COMMIT
		ED: https://opencaesar.github.io/vocabularies/
		Repository: https://github.com/opencaesar/vocabularies
		Editor: Jet Propulsion Laboratory
		!Copyright: Copyright 2019, by the California Institute of Technology. ALL RIGHTS RESERVED. United States Government Sponsorship acknowledged. Any commercial use must be negotiated with the Office of Technology Transfer at the California Institute of Technology.This software may be subject to U.S. export control laws. By accepting this software, the user agrees to comply with all applicable U.S. export laws and regulations. User has the responsibility to obtain export licenses, or other export authority as may be required before exporting such information to foreign countries or providing access to foreign persons.
		Boilerplate: copyright no, conformance no
		Markup Shorthands: markdown yes
		Use Dfn Panels: yes
		Abstract: Documentation generated from OML ontologies
		Favicon: https://opencaesar.github.io/assets/img/oml.png
		</pre>
		
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
		«val title = graph.title»
		
		# [«title»](./«relativePath».html) # {#heading-«graph.localName»}
		
	'''
	
	private def String getTitle(NamedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/title", element.name)
	}
}