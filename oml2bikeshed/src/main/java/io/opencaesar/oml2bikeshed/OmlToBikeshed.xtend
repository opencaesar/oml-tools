package io.opencaesar.oml2bikeshed

import io.opencaesar.oml.AnnotatedElement
import io.opencaesar.oml.AnnotationProperty
import io.opencaesar.oml.AnnotationPropertyReference
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.AspectReference
import io.opencaesar.oml.Bundle
import io.opencaesar.oml.BundleExtension
import io.opencaesar.oml.BundleInclusion
import io.opencaesar.oml.Classifier
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptInstance
import io.opencaesar.oml.ConceptInstanceReference
import io.opencaesar.oml.ConceptReference
import io.opencaesar.oml.Description
import io.opencaesar.oml.DescriptionExtension
import io.opencaesar.oml.DescriptionUsage
import io.opencaesar.oml.Element
import io.opencaesar.oml.Entity
import io.opencaesar.oml.EntityPredicate
import io.opencaesar.oml.EnumeratedScalar
import io.opencaesar.oml.EnumeratedScalarReference
import io.opencaesar.oml.FacetedScalar
import io.opencaesar.oml.FacetedScalarReference
import io.opencaesar.oml.Import
import io.opencaesar.oml.Member
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.RangeRestrictionKind
import io.opencaesar.oml.Reference
import io.opencaesar.oml.RelationEntity
import io.opencaesar.oml.RelationEntityPredicate
import io.opencaesar.oml.RelationEntityReference
import io.opencaesar.oml.RelationInstance
import io.opencaesar.oml.RelationInstanceReference
import io.opencaesar.oml.RelationPredicate
import io.opencaesar.oml.RelationRangeRestrictionAxiom
import io.opencaesar.oml.RelationReference
import io.opencaesar.oml.Rule
import io.opencaesar.oml.RuleReference
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.ScalarPropertyRangeRestrictionAxiom
import io.opencaesar.oml.ScalarPropertyReference
import io.opencaesar.oml.SpecializableTerm
import io.opencaesar.oml.SpecializableTermReference
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructureReference
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.StructuredPropertyReference
import io.opencaesar.oml.Vocabulary
import io.opencaesar.oml.VocabularyExtension
import java.util.ArrayList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.util.OmlIndex.*
import static extension io.opencaesar.oml.util.OmlRead.*
import static extension io.opencaesar.oml.util.OmlSearch.*

/**
 * Transform OML to Bikeshed
 * 
 * To produce documentation for a given ontology in OML we use Bikeshed as an intermediate form
 * that can be leveraged to produce the html output from a simpler Markdown specification.
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
	
	def String run() {
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
		Abstract: «ontology.description.replaceAll('\n', '\n ')»
	'''

	private def dispatch String toDiv(Vocabulary vocabulary) '''
		«vocabulary.toNamespace("# Namespace # {#Namespace}")»			
		«vocabulary.toImport("# Extensions # {#Extensions}", VocabularyExtension)»
		«vocabulary.toStatement("# Aspects # {#Aspects}", Aspect)»
		«vocabulary.toStatement("# External Aspects # {#ExternalAspects}", AspectReference)»
		«vocabulary.toStatement("# Concepts # {#concepts}", Concept)»
		«vocabulary.toStatement("# External Concepts # {#ExternalConcepts}", ConceptReference)»
		«vocabulary.toStatement("# Relations # {#Relations}", RelationEntity)»
		«vocabulary.toStatement("# External Relations # {#ExternalRelations}", #[RelationEntityReference, RelationReference])»
		«vocabulary.toStatement("# Structures # {#Structures}", Structure)»
		«vocabulary.toStatement("# External Structures # {#ExternalStructures}", StructureReference)»
		«vocabulary.toStatement("# Scalars # {#Scalars}", #[FacetedScalar, EnumeratedScalar])»
		«vocabulary.toStatement("# External Scalars # {#ExternalScalars}", #[FacetedScalarReference, EnumeratedScalarReference])»
		«vocabulary.toStatement("# Scalar Properties # {#ScalarProperties}", ScalarProperty)»
		«vocabulary.toStatement("# External Scalar Properties # {#ExternalScalarProperties}", ScalarPropertyReference)»
		«vocabulary.toStatement("# Structured Properties # {#StructuredProperties}", StructuredProperty)»
		«vocabulary.toStatement("# External Structured Properties # {#ExternalStructuredProperties}", StructuredPropertyReference)»
		«vocabulary.toStatement("# Annotation Properties # {#AnnotationProperties}", AnnotationProperty)»
		«vocabulary.toStatement("# External Annotation Properties # {#ExternalAnnotationProperties}", AnnotationPropertyReference)»
		«vocabulary.toStatement("# Rules # {#Rules}", Rule)»
		«vocabulary.toStatement("# External Rules # {#ExternalRules}", RuleReference)»
		
	'''
	
	private def dispatch String toDiv(Bundle bundle) '''
		«bundle.toNamespace("# Namespace # {#Namespace}")»			
		«bundle.toImport("# Inclusions # {#Inclusions}", BundleInclusion)»
		«bundle.toImport("# Extensions # {#Extensions}", BundleExtension)»
	'''

	private def dispatch String toDiv(Description description) '''
		«description.toNamespace("# Namespace # {#Namespace}")»
		«description.toImport("# Usages # {#Iclusions}", DescriptionUsage)»
		«description.toImport("# Extensions # {#Extensions}", DescriptionExtension)»
		«description.toImport("# Concept Instances # {#ConceptInstances}", ConceptInstance)»
		«description.toImport("# External Concept Instances # {#ExternalConceptInstances}", ConceptInstanceReference)»
		«description.toImport("# Relation Instances # {#ConceptInstances}", RelationInstance)»
		«description.toImport("# External Relation Instances # {#ExternalConceptInstances}", RelationInstanceReference)»
	'''

	// FIXME: this works for internal links to generated docs but not for links to external documentation. 
	private def String toNamespace(Ontology ontology, String heading) '''
		«heading»
		«val ontologyURI = ontology.eResource.URI.trimFileExtension.appendFileExtension('html').lastSegment»
			* «ontology.prefix»: [«ontology.iri»](«ontologyURI»)
			
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
	
	private def <T extends Element> String toStatement(Ontology ontology, String heading, Class<T>...types) '''
		«val elements = types.map[ontology.statements.filter(it)].flatten»
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
		«term.sectionHeader»
		
		«term.comment»
		
		«term.plainDescription»
		
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

	private def dispatch String toBikeshed(Entity entity) '''
		«entity.sectionHeader»
		
		«entity.comment»
		
		«entity.plainDescription»
		
		«val superEntities = entity.specializedTerms»
		«IF !superEntities.empty»

		*Super entities:*
		«superEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		«val subEntities = entity.findSpecializingTerms.filter(Entity)»
		«IF !subEntities.empty»

		*Specializations:*
		«subEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»

		«val domainRelations = entity.findRelationEntitiesWithSource»
		«IF !domainRelations.empty»
		*Relations having «entity.name» as domain:*
			«FOR dr :domainRelations.sortBy[name]»
			* «entity.name» «dr.forward.toBikeshedReference» «dr.target.toBikeshedReference» 
			«ENDFOR»
		
		«ENDIF»
		
		«val domainTransitiveRelations = entity.specializedTerms.filter(Entity).map(e | e.findRelationEntitiesWithSource).flatten»
		«IF !domainTransitiveRelations.empty»
		*Supertype Relations having «entity.name» as domain:*
			«FOR dr :domainTransitiveRelations.sortBy[name]»
			* «entity.name» «dr.forward.toBikeshedReference» «dr.target.toBikeshedReference» 
			«ENDFOR»
		«ENDIF»
		
		«val rangeRelations = entity.findRelationEntitiesWithTarget»
		«IF !rangeRelations.empty»
		*Relations having «entity.name» as range:*
			«FOR dr :rangeRelations.sortBy[name]»
			* «dr.source.toBikeshedReference» «dr.forward.toBikeshedReference» «entity.name» 
			«ENDFOR»
		«ENDIF»

		«val properties = entity.findFeaturePropertiesWithDomain»
		«IF !properties.empty»
		*Direct Properties:*
		«properties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		
		«val transitiveproperties = entity.specializedTerms.filter(Classifier).map(e | e.findFeaturePropertiesWithDomain).flatten»
		«IF !transitiveproperties.empty»
		*Supertype Properties:*
		«transitiveproperties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		
		«FOR r : entity.findRelationRestrictions»
			* «r.toBikeshed»
		«ENDFOR»
		«FOR r : entity.findPropertyRestrictions»
			* «r.toBikeshed»
		«ENDFOR»
	'''

	private def dispatch String toBikeshed(RelationEntity entity) '''
		«entity.sectionHeader»
	
		«entity.comment»
		
		«entity.plainDescription»
		
		«val attr=entity.relationshipAttributes»
		«IF attr !== null»
		*Attributes:* «attr»
		«ENDIF»
		
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
		
		«val properties = entity.findFeaturePropertiesWithDomain»
		«IF !properties.empty»
		*Direct Properties:*
		«properties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		
		«val transitiveproperties = entity.specializedTerms.filter(Classifier).map(e | e.findFeaturePropertiesWithDomain).flatten»
		«IF !transitiveproperties.empty»
		*Supertype Properties:*
		«transitiveproperties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
	'''
		
	// FacetedScalar
	private def dispatch String toBikeshed(FacetedScalar scalar) '''
		«scalar.sectionHeader»
		
		«scalar.comment»
		
		«scalar.plainDescription»

		«IF null!==scalar.length»*length:* «scalar.length.toString»«ENDIF»
		«IF null!==scalar.minLength»*min length:* «scalar.minLength.toString»«ENDIF»
		«IF null!==scalar.maxLength»*max length:* «scalar.maxLength.toString»«ENDIF»
		«IF null!==scalar.pattern»*pattern:* «scalar.pattern.toString»«ENDIF»
		«IF null!==scalar.language»*language:* «scalar.language.toString»«ENDIF»
		«IF null!==scalar.minInclusive»*min inclusive:* «scalar.minInclusive.lexicalValue»«ENDIF»
		«IF null!==scalar.minExclusive»*min exclusive:* «scalar.minExclusive.lexicalValue»«ENDIF»
		«IF null!==scalar.maxInclusive»*max inclusive:* «scalar.maxInclusive.lexicalValue»«ENDIF»
		«IF null!==scalar.maxExclusive»*max exclusive:* «scalar.maxExclusive.lexicalValue»«ENDIF»
	'''
	
	// EnumerationScalar
	private def dispatch String toBikeshed(EnumeratedScalar scalar) '''
		«scalar.sectionHeader»
		
		«scalar.comment»
		
		«scalar.plainDescription»
		
		*Values*: «scalar.literals.map['''«it.lexicalValue»'''].join(', ')»
		
	'''

	private def dispatch String toBikeshed(AnnotationProperty property) '''
		«property.sectionHeader»
		
		«property.comment»

		«property.plainDescription»
		
	'''
	
	private def dispatch String toBikeshed(ScalarProperty property) '''
		«property.sectionHeader»
		
		«property.comment»
		
		«property.plainDescription»
		
		«val domain = property.domain»
		*Domain:* <a spec="«domain.ontology?.iri»" lt="«domain.name»">«domain.getReferenceName(domain.ontology)»</a>
		
		«val range = property.range»
		*Scalar value type:* <a spec="«range.ontology?.iri»" lt="«range.name»">«range.getReferenceName(range.ontology)»</a>
		
		
		«IF property.functional»
		*Attributes:* Functional
		«ENDIF»
		
	'''

  	//TODO: find an ontology containing examples of this we can test against
	private def dispatch String toBikeshed(StructuredProperty property) '''
		«property.sectionHeader»
		
		«property.comment»
		
		«property.plainDescription»
		
	'''
		
	private def dispatch String toBikeshed(RelationRangeRestrictionAxiom axiom) '''
		«val range = axiom.range»
		«val relation = axiom.relation»
		«IF axiom.kind == RangeRestrictionKind.ALL»
			Restricts range of «relation.toBikeshedReference» to be an instance of «range.toBikeshedReference»
		«ELSE»
			Restricts range of «relation.toBikeshedReference» to some instances of «range.toBikeshedReference»
		«ENDIF»
	'''
	
	private def dispatch String toBikeshed(ScalarPropertyRangeRestrictionAxiom axiom) '''
		«val range = axiom.range»
		«val property = axiom.property»
		«IF axiom.kind == RangeRestrictionKind.ALL»
			Restricts range of «property.toBikeshedReference» to be an instance of «range.toBikeshedReference»
		«ELSE»
			Restricts range of «property.toBikeshedReference» to some instances of «range.toBikeshedReference»
		«ENDIF»
	'''
		
	// Inference rules have a set of set of antecedents and one consequent
	private def dispatch String toBikeshed(Rule rule) '''
		«rule.sectionHeader»
		
		«rule.consequent.toBikeshed» is implied when the following conditions are true
		
		«rule.antecedent.map[toBikeshed].join(" AND ")»
		
	'''
	
	private def dispatch String toBikeshed(EntityPredicate predicate) '''
		«predicate.entity.name»(«predicate.variable.toString»)
	'''
	
	private def dispatch String toBikeshed(RelationPredicate predicate) '''
		«predicate.relation.name»(«predicate.variable1.toString»,«predicate.variable2.toString»)
	'''
	
	private def dispatch String toBikeshed(RelationEntityPredicate predicate) '''
	«predicate.entity.name»(«predicate.variable1.toString»,«predicate.variable2.toString»)
	'''
	
	private def dispatch String toBikeshed(SpecializableTermReference reference) '''
		«val term = reference.resolve»
		## <a spec="«term.ontology.iri»" lt="«term.name»">«reference.resolvedName»</a> ## {#«reference.resolvedName.toFirstUpper»}
		«reference.comment»
		«val superTerms = reference.specializedTerms»
		«IF !superTerms.empty»

		*Super terms:*
		«superTerms.sortBy[name].map['''<a spec="«ontology.iri»">«name»</a>'''].join(', ')»
		«ENDIF»
		
	'''

	//----------------------------------------------------------------------------------------------------------

	private def String getRelationshipAttributes(RelationEntity entity) {
		val ArrayList<String> pnames=new ArrayList
		if (entity.functional) pnames.add("Functional")
		if (entity.inverseFunctional) pnames.add("InverseFunctional")
		if (entity.symmetric) pnames.add("Symmetric")
		if (entity.asymmetric) pnames.add("Asymmetric")
		if (entity.reflexive) pnames.add("Reflexive")
		if (entity.irreflexive) pnames.add("Irreflexive")
		if (entity.transitive) pnames.add("Transitive")
		pnames.join(", ")
	}

	private def String toBikeshedReferenceBase(Ontology ontology, Member member) 
	'''<a spec="«ontology.iri»" lt="«member.name»">«member.getReferenceName(ontology)»</a> '''
	
	private def String toBikeshedReference(Member member) {
		member.ontology.toBikeshedReferenceBase(member)
	}
	
	private def String getPlainDescription(Member member) {
		val desc=member.description
		if (desc.startsWith("http")) ""
		else 
			desc
	}
	
	/**
	 * Tricky bit: if description starts with a url we treat it as an
	 * external definition.
	 */
	private def String getSectionHeader(Member member) {
		val desc=member.description

		if (desc.startsWith("http"))
		'''## <dfn>«member.name»</dfn> see \[«member.name»](«desc») ## {#«member.name.toFirstUpper»}'''
		else
		'''## <dfn>«member.name»</dfn> ## {#«member.name.toFirstUpper»}'''
	}
	
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

	private def String getReferenceName(Member member, Ontology ontology) {
		val localName = member.getNameIn(ontology)
		localName ?: member.abbreviatedIri
	}
}