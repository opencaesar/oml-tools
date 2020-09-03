package io.opencaesar.oml.bikeshed

import io.opencaesar.oml.Ontology
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.util.OmlRead.*
import java.util.ArrayList

/**
 * Generate the index file. We produce this as a bikeshed spec as well in order to 
 * get the bikeshed styling.
 */
class Oml2Index {

	static def String addHeader() '''
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
		Local Boilerplate: logo yes
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
	val int index
	
	new(Resource inputResource, String relativePath, int index) {
		this.inputResource = inputResource
		this.relativePath = relativePath
		this.index = index
	}
	
	def String getDomain() {
		new java.net.URI(inputResource.ontology.iri).host
	}
	
	def String run() '''
		«val ontology = inputResource.ontology»
		
		## \[«ontology.title»](./«relativePath».html) ## {#heading-«ontology.prefix»-«index»}
		«ontology.description»		
		
	'''
	
	private static def String getTitle(Ontology ontology) {
		ontology.getAnnotationLexicalValue("http://purl.org/dc/elements/1.1/title") ?: ontology.prefix
	}

	private static def String getDescription(Ontology ontology) {
		ontology.getAnnotationLexicalValue("http://purl.org/dc/elements/1.1/description") ?: ""
	}
	
	static class Group {
		val members = new ArrayList<Oml2Index>
		
		def String run() {
			header + members.map[run].join('\n')
		}
		
		def String header() '''
			# «members.head.domain» # {#heading-domain-«members.head.domain»}
		'''
		
		def void add(Oml2Index member) {
			members += member
		}
	}
	
}