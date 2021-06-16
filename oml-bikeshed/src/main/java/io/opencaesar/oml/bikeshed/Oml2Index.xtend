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

import io.opencaesar.oml.AnnotatedElement
import io.opencaesar.oml.AnnotationProperty
import io.opencaesar.oml.Ontology
import java.net.URI
import java.util.ArrayList
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.util.OmlRead.*

/**
 * Generate the index file. We produce this as a bikeshed spec as well in order to 
 * get the bikeshed styling.
 */
class Oml2Index {

	static def String addHeader(String url) '''
		<pre class='metadata'>
		Title: OML Ontologies Index
		Shortname: Index
		Level: 1
		Status: LS-COMMIT
		ED: «url»
		Repository: «url»
		Editor: (see individual ontologies)
		!Copyright: (see individual ontologies)
		Boilerplate: copyright no, conformance no
		Local Boilerplate: logo yes
		Markup Shorthands: markdown yes, css no
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
		new URI(inputResource.ontology.iri).host
	}
	
	def String run() '''
		«val ontology = inputResource.ontology»
		
		## \[«ontology.title»](./«relativePath».html) ## {#heading-«ontology.prefix»-«index»}
		«ontology.description»		
		
	'''
	
	private static def String getAnnotationStringValue(AnnotatedElement element, String abbreviatedIri) {
		var property = element.getMemberByAbbreviatedIri(abbreviatedIri) as AnnotationProperty
		if (property !== null) {
			var value = element.getAnnotationValue(property)
			if (value !== null) {
				return value.stringValue	
			}
		}
		return null
	}

	private static def String getTitle(Ontology ontology) {
		ontology.getAnnotationStringValue("dc:title") ?: ontology.prefix 
	}

	private static def String getDescription(Ontology ontology) {
		ontology.getAnnotationStringValue("http://purl.org/dc/elements/1.1/description") ?: ""
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