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
import java.net.URI
import java.util.ArrayList

import static extension io.opencaesar.oml.bikeshed.OmlUtils.*

/**
 * Generate the index file. We produce this as a bikeshed spec as well in order to 
 * get the bikeshed styling.
 */
class Oml2Index {

	static def String addHeader(String url, String title, String version) '''
		<pre class='metadata'>
		Title: «title?:"OML Ontologies Index"» «version?:""»
		Shortname: Index
		Level: 1
		Status: LS
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
	
	val Ontology ontology
	val String relativePath
	val int index
	
	new(Ontology ontology, String relativePath, int index) {
		this.ontology = ontology
		this.relativePath = relativePath
		this.index = index
	}
	
	def String getDomain() {
		new URI(ontology.iri).host
	}
	
	def String run() '''
		
		## \[«ontology.title»](./«relativePath».html) ## {#heading-«ontology.prefix»-«index»}
		«ontology.description»
		«IF ontology.isDeprecated»
		<div class=note>
		This ontology has been deprecated
		</div>
		«ENDIF»
	'''
	
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