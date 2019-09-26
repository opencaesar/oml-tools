package io.opencaesar.oml2bikeshed

import io.opencaesar.oml.AnnotatedElement
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.AspectReference
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptReference
import io.opencaesar.oml.Description
import io.opencaesar.oml.Graph
import io.opencaesar.oml.NamedElement
import io.opencaesar.oml.ReifiedRelationship
import io.opencaesar.oml.ReifiedRelationshipReference
import io.opencaesar.oml.Relationship
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.ScalarPropertyReference
import io.opencaesar.oml.ScalarRange
import io.opencaesar.oml.ScalarRangeReference
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructureReference
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.StructuredPropertyReference
import io.opencaesar.oml.Term
import io.opencaesar.oml.TermReference
import io.opencaesar.oml.Terminology
import io.opencaesar.oml.TerminologyExtension
import io.opencaesar.oml.UnreifiedRelationship
import io.opencaesar.oml.UnreifiedRelationshipReference
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.Oml.*
import static extension io.opencaesar.oml.util.OmlCrossReferencer.*
import io.opencaesar.oml.Entity
import io.opencaesar.oml.CharacterizationProperty
import io.opencaesar.oml.LiteralValue

/**
 * Transform OML to Bikeshed
 * 
 * To produce documentation for a given ontology in OML we use Bikeshed as an intermediate form
 * that can be leveraged to produce the html output from a simpler markdown specificaiton.
 * 
 * See: OML Reference https://opencaesar.github.io/oml-spec/
 * See: Bikeshed Reference https://tabatkins.github.io/bikeshed/
 * 
 */
class OmlToBikeshed {

	val Resource inputResource 
	val String url
	val String relativePath

	new(Resource inputResource, String url, String relativePath) {
		this.inputResource = inputResource
		this.url = url
		this.relativePath = relativePath
	}
	
	def run() {
		inputResource.graph.toBikeshed
	}
	
	private def dispatch String toBikeshed(Graph graph) '''
		<pre class='metadata'>
		«graph.toPre»
		</pre>
		<div export=true>
		«graph.toDiv»
		</div>
	'''
		
	private def String toPre(Graph graph) '''
		Title: «graph.title»
		Shortname: «graph.name»
		Level: 1
		Status: LS-COMMIT
		ED: «url»/«relativePath»
		Repository: «url»
		Editor: «graph.creator»
		!Copyright: «graph.copyright»
		Boilerplate: copyright no, conformance no
		Markup Shorthands: markdown yes
		Use Dfn Panels: yes
		Abstract: «graph.description»
	'''

	private def dispatch String toDiv(Terminology terminology) '''
		«terminology.toNamespace("# Namespace # {#heading-namespace}")»			
		«terminology.toImports("# Imports # {#heading-imports}")»
		«terminology.toSubsection(Aspect, "# Aspects # {#heading-aspects}")»
		«terminology.toSubsection(AspectReference, "# External Aspects # {#heading-external-aspects}")»
		«terminology.toSubsection(Concept, "# Concepts # {#heading-concepts}")»
		«terminology.toSubsection(ConceptReference, "# External Concepts # {#heading-external-concepts}")»
		«terminology.toSubsection(ReifiedRelationship, "# Reified Relationships # {#heading-reifiedrelationships}")»
		«terminology.toSubsection(ReifiedRelationshipReference, "# External Reified Relationships # {#heading-external-reifiedrelationships}")»
		«terminology.toSubsection(UnreifiedRelationship, "# Unreified Relationships # {#heading-unreifiedrelationships}")»
		«terminology.toSubsection(UnreifiedRelationshipReference, "# External Unreified Relationships # {#heading-external-unreifiedrelationships}")»
		«terminology.toSubsection(Structure, "# Structures # {#heading-structures}")»
		«terminology.toSubsection(StructureReference, "# External Structures # {#heading-external-structures}")»
		«terminology.toSubsection(ScalarRange, "# Scalars # {#heading-scalars}")»
		«terminology.toSubsection(ScalarRangeReference, "# External Structures # {#heading-external-scalars}")»
		«terminology.toSubsection(StructuredProperty, "# Structured Properties # {#heading-structuredproperties}")»
		«terminology.toSubsection(StructuredPropertyReference, "# External Structured Properties # {#heading-external-structuredproperties}")»
		«terminology.toSubsection(ScalarProperty, "# Scalar Properties # {#heading-scalarproperties}")»
		«terminology.toSubsection(ScalarPropertyReference, "# External Scalar Properties # {#heading-external-scalarproperties}")»
		
	'''
	
	private def dispatch String toDiv(Description description) '''
		«description.toNamespace("# Namespace # {#heading-namespace}")»			
	'''

	private def String toNamespace(Graph graph, String heading) '''
		«heading»
			«val importURI = graph.eResource.URI.trimFileExtension.appendFileExtension('html').lastSegment»
			* «graph.name»: [«graph.iri»](«importURI»)
	'''
	
	private def String toImports(Terminology terminology, String heading) '''
		«heading»
		*Extensions:*
			«FOR _extension : terminology.imports.filter(TerminologyExtension)»
			«val importURI = URI.createURI(_extension.importURI).trimFileExtension.appendFileExtension('html')»
			* «_extension.importAlias»: [«_extension.importedGraph.iri»](«importURI»)
			«ENDFOR»
	'''

	private def <T extends AnnotatedElement> String toSubsection(Terminology terminology, Class<T> type, String heading) '''
		«val elements = terminology.statements.filter(type)»
		«IF !elements.empty»
		«heading»
		«FOR element : elements»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''

	private def dispatch String toBikeshed(Term term) '''
		## <dfn>«term.name»</dfn> ## {#heading-«term.localName»}
		«term.comment»
		«val superTerms = term.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(term.graph)»</a>'''].join(', ')»
		«ENDIF»
		«val subTerms = term.allSpecializingTerms»
		«IF !subTerms.empty»

		*Sub terms:*
		«subTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(term.graph)»</a>'''].join(', ')»
		«ENDIF»
		
	'''

	// TODO: inherited relations
	// TODO: inherited properties
	// TODO: annotation properties?
	private def dispatch String toBikeshed(Entity entity) '''
		## <dfn>«entity.name»</dfn> ## {#heading-«entity.localName»}
		«entity.comment»
		«val superEntities = entity.specializedTerms»
		«IF !superEntities.empty»

		*Super entities:*
		«superEntities.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»
		«val subEntities = entity.allSpecializingEntities»
		«IF !subEntities.empty»

		*Sub entities:*
		«subEntities.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»

		«val domainRelations = entity.allSourceReifiedRelations»
		«IF !domainRelations.empty»
		*Relations having «entity.localName» as domain:*
		«domainRelations.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»
		
		«val rangeRelations = entity.allTargetReifiedRelations»
		«IF !rangeRelations.empty»
		*Relations having «entity.localName» as range:*
		«rangeRelations.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»

		«val properties = entity.allSourceProperties»
		«IF !properties.empty»
		*Properties:*
		«properties.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(entity.graph)»</a>'''].join(', ')»
		«ENDIF»

	'''
	
	private def String toBikeshedHelper(Relationship relationship) '''
		## <dfn>«relationship.name»</dfn> ## {#heading-«relationship.localName»}
		«relationship.comment»
		*Source:*
		«val source = relationship.source»
		<a spec="«source.graph.iri»" lt="«source.name»">«source.getReferenceName(relationship.graph)»</a>

		*Target:*
		«val target = relationship.target»
		<a spec="«target.graph.iri»" lt="«target.name»">«target.getReferenceName(relationship.graph)»</a>

		*Forward:*
		<dfn attribute for=«relationship.name»>«relationship.forward.name»</dfn>
		«relationship.forward.description»
		«IF relationship.inverse !== null»

		*Inverse:*
		<dfn attribute for=«relationship.name»>«relationship.inverse.name»</dfn>
		«relationship.inverse.description»
		«ENDIF»
		«val superTerms = relationship.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(relationship.graph)»</a>'''].join(', ')»
		«ENDIF»
		«val subTerms = relationship.allSpecializingTerms»
		«IF !subTerms.empty»

		*Sub terms:*
		«subTerms.sortBy[name].map['''<a spec="«graph.iri»" lt="«name»">«getReferenceName(relationship.graph)»</a>'''].join(', ')»
		«ENDIF»
	'''

	private def dispatch String toBikeshed(ReifiedRelationship relationship) {
		toBikeshedHelper(relationship)
	}
	
	private def dispatch String toBikeshed(Relationship relationship) {
		toBikeshedHelper(relationship)
	}
	
//  TODO: find an ontology containing examples of this we can test against
//	private def dispatch String toBikeshed(StructuredProperty property) '''
//		## <dfn>«property.name»</dfn> ## {#heading-«property.localName»}
//		«property.comment»
//		
//		Structured range described by...
//	'''
	
	private def dispatch String toBikeshed(ScalarProperty property) '''
		## <dfn>«property.name»</dfn> ## {#heading-«property.localName»}
		«property.comment»
		«val range = property.range»
		Scalar range type: <a spec="«range.graph.iri»" lt="«range.name»">«range.getReferenceName(range.graph)»</a>
	'''
//	
//	private def dispatch String toBikesshed(ScalarRange range) '''
//		## <dfn>«range.name»</dfn> ## {#heading-«range.localName»}
//		«range.comment»
//		range definition...
//	'''
	
	
	private def dispatch String toBikeshed(TermReference reference) '''
		«val term = reference.resolve»
		## <a spec="«term.graph.iri»" lt="«term.name»">«reference.localName»</a> ## {#heading-«reference.localName»}
		«reference.comment»
			«val superTerms = reference.specializedTerms»
			«IF !superTerms.empty»

			*Super terms:*
			«superTerms.sortBy[name].map['''<a spec="«graph.iri»">«name»</a>'''].join(', ')»
			«ENDIF»
		
	'''

	//----------------------------------------------------------------------------------------------------------

	private def String getTitle(NamedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/title", element.name)
	}
	
	private def String getDescription(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/description", "")
	}

	private def String getCreator(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/creator", "Unknown")
	}

	private def String getCopyright(AnnotatedElement element) {
		element.getAnnotationStringValue("http://purl.org/dc/elements/1.1/rights", "").replaceAll('\n', '')
	}

	private def String getComment(AnnotatedElement element) {
		element.getAnnotationStringValue("http://www.w3.org/2000/01/rdf-schema#comment", "")
	}
	
	private def String getReferenceName(NamedElement referenced, Graph graph) {
		val localName = referenced.getLocalNameIn(graph)
		localName ?: referenced.qualifiedName
	}
}