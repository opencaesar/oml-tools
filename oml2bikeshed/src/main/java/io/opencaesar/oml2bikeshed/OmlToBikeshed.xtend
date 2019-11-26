package io.opencaesar.oml2bikeshed

import io.opencaesar.oml.AnnotatedElement
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.AspectReference
import io.opencaesar.oml.Bundle
import io.opencaesar.oml.BundleExtension
import io.opencaesar.oml.BundleInclusion
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptReference
import io.opencaesar.oml.Description
import io.opencaesar.oml.Element
import io.opencaesar.oml.Entity
import io.opencaesar.oml.EnumeratedScalar
import io.opencaesar.oml.EnumeratedScalarReference
import io.opencaesar.oml.FacetedScalar
import io.opencaesar.oml.FacetedScalarReference
import io.opencaesar.oml.IdentifiedElement
import io.opencaesar.oml.Import
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.Reference
import io.opencaesar.oml.RelationEntity
import io.opencaesar.oml.RelationEntityReference
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.ScalarPropertyReference
import io.opencaesar.oml.SpecializableTerm
import io.opencaesar.oml.SpecializableTermReference
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructureReference
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.StructuredPropertyReference
import io.opencaesar.oml.Vocabulary
import io.opencaesar.oml.VocabularyExtension
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.util.OmlIndex.*
import static extension io.opencaesar.oml.util.OmlRead.*
import static extension io.opencaesar.oml.util.OmlSearch.*

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
		inputResource.ontology.toBikeshed
	}

	private def dispatch String toBikeshed(Element element) '''
	'''
		
	private def dispatch String toBikeshed(Ontology ontology) '''
		<pre class='metadata'>
		«ontology.toPre»
		</pre>
		<div export=true>
		«ontology.toDiv»
		</div>
		<style>
		a[data-link-type=biblio] {
		    white-space: pre-wrap;
		}
		</style>
	'''
		
	private def String toPre(Ontology ontology) '''
		Title: «ontology.title»
		Shortname: «ontology.prefix»
		Level: 1
		Status: LS-COMMIT
		ED: «url»/«relativePath»
		Repository: «url»
		Editor: «ontology.creator.replaceAll(',', '')»
		!Copyright: «ontology.copyright»
		Boilerplate: copyright no, conformance no
		Markup Shorthands: markdown yes
		Use Dfn Panels: yes
		Abstract: «ontology.description»
	'''

	private def dispatch String toDiv(Vocabulary vocabulary) '''
		«vocabulary.toNamespace("# Namespace # {#heading-namespace}")»			
		«vocabulary.toImport("# Extensions # {#heading-extensions}", VocabularyExtension)»
		«vocabulary.toStatement("# Aspects # {#heading-aspects}", Aspect)»
		«vocabulary.toStatement("# External Aspects # {#heading-external-aspects}", AspectReference)»
		«vocabulary.toStatement("# Concepts # {#heading-concepts}", Concept)»
		«vocabulary.toStatement("# External Concepts # {#heading-external-concepts}", ConceptReference)»
		«vocabulary.toStatement("# Relations # {#heading-relations}", RelationEntity)»
		«vocabulary.toStatement("# External Relations # {#heading-external-relations}", RelationEntityReference)»
		«vocabulary.toStatement("# Structures # {#heading-structures}", Structure)»
		«vocabulary.toStatement("# External Structures # {#heading-external-structures}", StructureReference)»
		«vocabulary.toStatement("# Scalars # {#heading-scalars}", #[FacetedScalar, EnumeratedScalar])»
		«vocabulary.toStatement("# External Scalars # {#heading-external-scalars}", #[FacetedScalarReference, EnumeratedScalarReference])»
		«vocabulary.toStatement("# Structured Properties # {#heading-structuredproperties}", StructuredProperty)»
		«vocabulary.toStatement("# External Structured Properties # {#heading-external-structuredproperties}", StructuredPropertyReference)»
		«vocabulary.toStatement("# Scalar Properties # {#heading-scalarproperties}", ScalarProperty)»
		«vocabulary.toStatement("# External Scalar Properties # {#heading-external-scalarproperties}", ScalarPropertyReference)»
		
	'''

	private def dispatch String toDiv(Bundle bundle) '''
		«bundle.toNamespace("# Namespace # {#heading-namespace}")»			
		«bundle.toImport("# Extensions # {#heading-extensions}", BundleExtension)»
		«bundle.toImport("# Inclusions # {#heading-inclusions}", BundleInclusion)»
	'''
		
	private def dispatch String toDiv(Description description) '''
		«description.toNamespace("# Namespace # {#heading-namespace}")»			
	'''

	private def String toNamespace(Ontology ontology, String heading) '''
		«heading»
			«val importURI = ontology.eResource.URI.trimFileExtension.appendFileExtension('html').lastSegment»
			* «ontology.prefix»: [«ontology.iri»](«importURI»)
	'''
	
	private def <T extends Element> String toStatement(Ontology ontology, String heading, Class<T>...types) '''
		«val elements = types.map[type|ontology.statements.filter(type)].flatten»
		«IF !elements.empty»
		«heading»
		«FOR element : elements»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''

	private def <T extends Element> String toImport(Ontology ontology, String heading, Class<T>...types) '''
		«val elements = types.map[type|ontology.importsWithSource.filter(type)].flatten»
		«IF !elements.empty»
		«heading»
		«FOR element : elements»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''
	private def dispatch String toBikeshed(Import ^import) '''
		«val importURI = URI.createURI(^import.uri).trimFileExtension.appendFileExtension('html')»
			* «^import.importPrefix»: [«^import.importedOntology.iri»](«importURI»)
	'''

	private def dispatch String toBikeshed(SpecializableTerm term) '''
		## <dfn>«term.name»</dfn> ## {#heading-«term.name»}
		«term.comment»
		«val superTerms = term.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(term.ontology)»</a>'''].join(', ')»
		«ENDIF»
		«val subTerms = term.findSpecializingTerms»
		«IF !subTerms.empty»

		*Sub terms:*
		«subTerms.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(term.ontology)»</a>'''].join(', ')»
		«ENDIF»
		
	'''

	// TODO: inherited relations
	// TODO: inherited properties
	// TODO: annotation properties?
	private def dispatch String toBikeshed(Entity entity) '''
		## <dfn>«entity.name»</dfn> ## {#heading-«entity.name»}
		«entity.comment»
		«entity.description»
		
		«val superEntities = entity.specializedTerms»
		«IF !superEntities.empty»

		*Super entities:*
		«superEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		«val subEntities = entity.findSpecializingTerms.filter(Entity)»
		«IF !subEntities.empty»

		*Sub entities:*
		«subEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»

		«val domainRelations = entity.findRelationEntitiesWithSource»
		«IF !domainRelations.empty»
		*Relations having «entity.name» as domain:*
		«domainRelations.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		
		«val rangeRelations = entity.findRelationEntitiesWithTarget»
		«IF !rangeRelations.empty»
		*Relations having «entity.name» as range:*
		«rangeRelations.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»

		«val properties = entity.findFeaturePropertiesWithDomain»
		«IF !properties.empty»
		*Properties:*
		«properties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»

	'''
	
	private def dispatch String toBikeshed(RelationEntity entity) '''
		## <dfn>«entity.name»</dfn> ## {#heading-«entity.name»}
		«entity.comment»
		«entity.description»
		
		*Source:*
		«val source = entity.source»
		<a spec="«source.ontology.iri»" lt="«source.name»">«source.getReferenceName(entity.ontology)»</a>

		*Target:*
		«val target = entity.target»
		<a spec="«target.ontology.iri»" lt="«target.name»">«target.getReferenceName(entity.ontology)»</a>

		*Forward:*
		<dfn attribute for=«entity.name»>«entity.forward.name»</dfn>
		«entity.forward.description»
		«IF entity.inverse !== null»

		*Inverse:*
		<dfn attribute for=«entity.name»>«entity.inverse.name»</dfn>
		«entity.inverse.description»
		«ENDIF»
		«val superTerms = entity.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		«val subTerms = entity.findSpecializingTerms»
		«IF !subTerms.empty»

		*Sub terms:*
		«subTerms.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
	'''	
	
//  TODO: find an ontology containing examples of this we can test against
//	private def dispatch String toBikeshed(StructuredProperty property) '''
//		## <dfn>«property.name»</dfn> ## {#heading-«property.name»}
//		«property.comment»
//		
//		Structured range described by...
//	'''
	
	private def dispatch String toBikeshed(ScalarProperty property) '''
		## <dfn>«property.name»</dfn> ## {#heading-«property.name»}
		«property.comment»
		«property.description»
		«val range = property.range»
		Scalar property type: <a spec="«range.ontology.iri»" lt="«range.name»">«range.getReferenceName(range.ontology)»</a>
	'''
	
	private def dispatch String toBikeshed(SpecializableTermReference reference) '''
		«val term = reference.resolve»
		## <a spec="«term.ontology.iri»" lt="«term.name»">«reference.resolvedName»</a> ## {#heading-«reference.resolvedName»}
		«reference.comment»
			«val superTerms = reference.specializedTerms»
			«IF !superTerms.empty»

			*Super terms:*
			«superTerms.sortBy[name].map['''<a spec="«ontology.iri»">«name»</a>'''].join(', ')»
			«ENDIF»
		
	'''

	//----------------------------------------------------------------------------------------------------------

	private def String getTitle(Ontology ontology) {
		ontology.getAnnotationLexicalValue("http://purl.org/dc/elements/1.1/title") ?: ontology.prefix
	}
	
	private def String getDescription(AnnotatedElement element) {
		element.getAnnotationLexicalValue("http://purl.org/dc/elements/1.1/description") ?: ""
	}

	private def String getCreator(AnnotatedElement element) {
		element.getAnnotationLexicalValue("http://purl.org/dc/elements/1.1/creator") ?: "Unknown"
	}

	private def String getCopyright(AnnotatedElement element) {
		(element.getAnnotationLexicalValue("http://purl.org/dc/elements/1.1/rights") ?: "").replaceAll('\n', '')
	}

	private def String getComment(AnnotatedElement element) {
		element.getAnnotationLexicalValue("http://www.w3.org/2000/01/rdf-schema#comment") ?: ""
	}
	
	private def String getComment(Reference reference) {
		reference.getAnnotationLexicalValue("http://www.w3.org/2000/01/rdf-schema#comment") ?: ""
	}

	private def String getReferenceName(IdentifiedElement referenced, Ontology ontology) {
		val name = referenced.getNameIn(ontology)
		name ?: referenced.abbreviatedIri
	}
}