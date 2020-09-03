package io.opencaesar.oml.bikeshed

import io.opencaesar.oml.AnnotatedElement
import io.opencaesar.oml.AnnotationProperty
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptInstance
import io.opencaesar.oml.ConceptInstanceReference
import io.opencaesar.oml.Description
import io.opencaesar.oml.DescriptionBundle
import io.opencaesar.oml.DescriptionBundleExtension
import io.opencaesar.oml.DescriptionBundleInclusion
import io.opencaesar.oml.DescriptionBundleUsage
import io.opencaesar.oml.DescriptionExtension
import io.opencaesar.oml.DescriptionUsage
import io.opencaesar.oml.DifferentFromPredicate
import io.opencaesar.oml.Element
import io.opencaesar.oml.Entity
import io.opencaesar.oml.EntityPredicate
import io.opencaesar.oml.EnumeratedScalar
import io.opencaesar.oml.FacetedScalar
import io.opencaesar.oml.Import
import io.opencaesar.oml.Member
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.RangeRestrictionKind
import io.opencaesar.oml.Reference
import io.opencaesar.oml.RelationEntity
import io.opencaesar.oml.RelationEntityPredicate
import io.opencaesar.oml.RelationInstance
import io.opencaesar.oml.RelationInstanceReference
import io.opencaesar.oml.RelationPredicate
import io.opencaesar.oml.RelationRangeRestrictionAxiom
import io.opencaesar.oml.Rule
import io.opencaesar.oml.SameAsPredicate
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.ScalarPropertyRangeRestrictionAxiom
import io.opencaesar.oml.SpecializableTerm
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.Vocabulary
import io.opencaesar.oml.VocabularyBundle
import io.opencaesar.oml.VocabularyBundleExtension
import io.opencaesar.oml.VocabularyBundleInclusion
import io.opencaesar.oml.VocabularyExtension
import java.util.ArrayList
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource

import static extension io.opencaesar.oml.util.OmlIndex.*
import static extension io.opencaesar.oml.util.OmlRead.*
import static extension io.opencaesar.oml.util.OmlSearch.*
import io.opencaesar.oml.FeatureProperty
import io.opencaesar.oml.PropertyRestrictionAxiom
import io.opencaesar.oml.Relation
import io.opencaesar.oml.RelationRestrictionAxiom
import io.opencaesar.oml.RelationTargetRestrictionAxiom
import io.opencaesar.oml.RelationCardinalityRestrictionAxiom
import io.opencaesar.oml.ForwardRelation
import io.opencaesar.oml.ReverseRelation
import io.opencaesar.oml.ScalarPropertyRestrictionAxiom
import io.opencaesar.oml.ScalarPropertyCardinalityRestrictionAxiom
import io.opencaesar.oml.ScalarPropertyValueRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyRangeRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyCardinalityRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyValueRestrictionAxiom

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
class Oml2Bikeshed {

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
		Local Boilerplate: logo yes
		Markup Shorthands: markdown yes
		Use Dfn Panels: yes
		External Infotrees: anchors.bsdata yes
		Abstract: «ontology.description.replaceAll('\n', '\n ')»
	'''

	private def dispatch String toDiv(Vocabulary vocabulary) '''
		«vocabulary.toNamespace("# Namespace # {#Namespace}")»			
		«vocabulary.toImport("# Imports # {#Extensions}", VocabularyExtension)»
		«vocabulary.toStatement("# Concepts # {#concepts}", Concept)»
		«vocabulary.toStatement("# Aspects # {#Aspects}", Aspect)»
		«vocabulary.toStatement("# Relation Entities # {#Relations}", RelationEntity)»
		«vocabulary.toStatement("# Structures # {#Structures}", Structure)»
		«vocabulary.toStatement("# Scalars # {#Scalars}", #[FacetedScalar, EnumeratedScalar])»
		«vocabulary.toStatement("# Annotation Properties # {#AnnotationProperties}", AnnotationProperty)»
		«vocabulary.toStatement("# Structured Properties # {#StructuredProperties}", StructuredProperty)»
		«vocabulary.toStatement("# Scalar Properties # {#ScalarProperties}", ScalarProperty)»
		«vocabulary.toStatement("# Rules # {#Rules}", Rule)»
	'''
	
	private def dispatch String toDiv(VocabularyBundle bundle) '''
		«bundle.toNamespace("# Namespace # {#Namespace}")»			
		«bundle.toImport("# Extensions # {#Extensions}", VocabularyBundleExtension)»
		«bundle.toImport("# Inclusions # {#Inclusions}", VocabularyBundleInclusion)»
	'''

	private def dispatch String toDiv(Description description) '''
		«description.toNamespace("# Namespace # {#Namespace}")»
		«description.toImport("# Extensions # {#Extensions}", DescriptionExtension)»
		«description.toImport("# Usages # {#Iclusions}", DescriptionUsage)»
		«description.toImport("# Concept Instances # {#ConceptInstances}", ConceptInstance)»
		«description.toImport("# External Concept Instances # {#ExternalConceptInstances}", ConceptInstanceReference)»
		«description.toImport("# Relation Instances # {#ConceptInstances}", RelationInstance)»
		«description.toImport("# External Relation Instances # {#ExternalConceptInstances}", RelationInstanceReference)»
	'''

	private def dispatch String toDiv(DescriptionBundle bundle) '''
		«bundle.toNamespace("# Namespace # {#Namespace}")»			
		«bundle.toImport("# Extensions # {#Extensions}", DescriptionBundleExtension)»
		«bundle.toImport("# Inclusions # {#Inclusions}", DescriptionBundleInclusion)»
		«bundle.toImport("# Usages # {#Usages}", DescriptionBundleUsage)»
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
			* «^import.importPrefix»: [«^import.importedOntology?.iri»](«importURI»)
	'''

	private def dispatch String toBikeshed(SpecializableTerm term) '''
		«term.sectionHeader»
		
		«term.comment»
		
		«term.plainDescription»
		
		«val superTerms = term.findSpecializedTerms»
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
		
		«IF entity instanceof RelationEntity»
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

			*Forward Relation:*
			<dfn attribute for=«entity.name»>«entity.forward.name»</dfn>
			«entity.forward.description»
			«IF entity.reverse !== null»

			*Reverse Relation:*
			<dfn attribute for=«entity.name»>«entity.reverse.name»</dfn>
			«entity.reverse.description»
			«ENDIF»
		«ENDIF»
		
		«val superEntities = entity.findSpecializedTerms»
		«IF !superEntities.empty»

		*Supertypes:*
		«superEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		«val subEntities = entity.findSpecializingTerms.filter(Entity)»
		«IF !subEntities.empty»

		*Subtypes:*
		«subEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDIF»
		
		«val propertyRestrictions = entity.findPropertyRestrictions.toList»

		«val propertiesDirect = entity.findFeaturePropertiesWithDomain»
		«val propertiesWithRestrictions = propertyRestrictions.map[restrictedTerm].filter(FeatureProperty) »
		«val properties = (propertiesDirect + propertiesWithRestrictions).toSet»
		
		«IF !properties.empty »
		*Properties with domain:*
		«properties.sortBy[name].map[getPropertyDescription(entity.ontology, propertyRestrictions)].join(', ')»
		«ENDIF»

		«val keys = entity.findKeys»
		«IF !keys.empty»
		«FOR key : keys»
			* Key «key.properties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')»
		«ENDFOR»
		«ENDIF»
		
		«val relationRestrictions = entity.findRelationRestrictions.toList »

		«val domainRelationsDirect = entity.findRelationEntitiesWithSource»
		«val domainRelationsWithRangeRestrictions = relationRestrictions.map[relation].filter(ForwardRelation).map[it.entity] »
		«val domainRelations = (domainRelationsDirect + domainRelationsWithRangeRestrictions).toSet »
		
		«IF !domainRelations.empty »
		*Relations with domain:*
			«FOR dr : domainRelations.sortBy[name]»
			* «entity.name» «entity.ontology.toBikeshedReference(dr.forward)» «entity.ontology.toBikeshedReference(getRestrictedType(dr.forward, dr.target, entity.ontology, relationRestrictions))» «entity.ontology.noteRelationRestrictions(dr.forward, relationRestrictions)»
			«ENDFOR»
		«ENDIF»
		
		«val rangeRelationsDirect = entity.findRelationEntitiesWithTarget»
		«val rangeRelationsWithDomainRestrictions = relationRestrictions.map[relation].filter(ReverseRelation).map[it.entity] »
		«val rangeRelations = (rangeRelationsDirect + rangeRelationsWithDomainRestrictions).toSet »
				
		«IF !rangeRelations.empty »
		*Relations with range:*
			«FOR dr : rangeRelations.sortBy[name]»
			* «entity.ontology.toBikeshedReference(getRestrictedType(dr.reverse, dr.source, entity.ontology, relationRestrictions))» «entity.ontology.toBikeshedReference(dr.forward)» «entity.name» «entity.ontology.noteRelationRestrictions(dr.reverse, relationRestrictions)»
			«ENDFOR»
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
		
	// Inference rules have a set of set of antecedents and one consequent
	private def dispatch String toBikeshed(Rule rule) '''
		«rule.sectionHeader»
		
		«rule.antecedent.map[toBikeshed].join(" ∧ ")» -> «rule.consequent.map[toBikeshed].join(" ∧ ")»
	'''
	
	private def dispatch String toBikeshed(EntityPredicate predicate) '''
		«predicate.entity.name»(«predicate.variable.toString»)
	'''
		
	private def dispatch String toBikeshed(RelationEntityPredicate predicate) '''
		«predicate.entity.name»(«predicate.variable1.toString», «predicate.entityVariable.toString», «predicate.variable2.toString»)
	'''
	
	private def dispatch String toBikeshed(RelationPredicate predicate) '''
		«predicate.relation.name»(«predicate.variable1.toString», «predicate.variable2.toString»)
	'''

	private def dispatch String toBikeshed(SameAsPredicate predicate) '''
		sameAs(«predicate.variable1.toString», «predicate.variable2.toString»)
	'''

	private def dispatch String toBikeshed(DifferentFromPredicate predicate) '''
		differentFrom(«predicate.variable1.toString», «predicate.variable2.toString»)
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
	
	private def String toBikeshedReference(Ontology scope, Member member) 
	'''<a spec="«member.ontology.iri»" lt="«member.name»">«member.getReferenceName(scope)»</a>'''
	
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
	
	private dispatch def String getPropertyDescription(ScalarProperty property, Ontology context, Iterable<PropertyRestrictionAxiom> restrictions) {
		val baseDescription = '''<a spec="«context.iri»" lt="«property.name»">«property.getReferenceName(context)»</a>'''
		
		val restrictionDescriptions = restrictions
			.filter(ScalarPropertyRestrictionAxiom)
			.filter[it.property == property]
			.map[axiom|
				switch (axiom) {
					ScalarPropertyRangeRestrictionAxiom: {
						val range = axiom.range
						if (axiom.kind == RangeRestrictionKind.ALL) {
							'''must be of type «context.toBikeshedReference(range)»'''
						} else {
							'''must include instance of «context.toBikeshedReference(range)»'''
						}
					}
					ScalarPropertyCardinalityRestrictionAxiom: {
						val kind = switch (axiom.kind) {
							case EXACTLY: "exactly"
							case MIN: "at least"
							case MAX: "at most"
						}
						'''must have «kind» «axiom.cardinality»'''
					}
					ScalarPropertyValueRestrictionAxiom: {
						'''must have value «axiom.value.literalValue»'''
					}
					default: axiom.toString
				}
				
			]
			.join(", ")
			
		if (restrictionDescriptions.empty) {
			baseDescription
		} else {
			baseDescription + " (" + restrictionDescriptions + ")"
		}
	}
	
	private dispatch def String getPropertyDescription(StructuredProperty property, Ontology context, Iterable<PropertyRestrictionAxiom> restrictions) {
		val baseDescription = '''<a spec="«context.iri»" lt="«property.name»">«property.getReferenceName(context)»</a>'''
		
		val restrictionDescriptions = restrictions
			.filter(StructuredPropertyRestrictionAxiom)
			.filter[it.property == property]
			.map[axiom|
				switch (axiom) {
					StructuredPropertyRangeRestrictionAxiom: {
						val range = axiom.range
						if (axiom.kind == RangeRestrictionKind.ALL) {
							'''must be of type «context.toBikeshedReference(range)»'''
						} else {
							'''must include at least some «context.toBikeshedReference(range)»'''
						}
					}
					StructuredPropertyCardinalityRestrictionAxiom: {
						val kind = switch (axiom.kind) {
							case EXACTLY: "exactly"
							case MIN: "at least"
							case MAX: "at most"
						}
						'''must have «kind» «axiom.cardinality»'''
					}
					StructuredPropertyValueRestrictionAxiom: {
						'''must have specific value'''
					}
					default: axiom.toString
				}
				
			]
			.join(", ")
		
		if (restrictionDescriptions.empty) {
			baseDescription
		} else {
			baseDescription + " (" + restrictionDescriptions + ")"
		}
	}
	
	private def Entity getRestrictedType(Relation relation, Entity baseType, Ontology context, Iterable<RelationRestrictionAxiom> restrictions) {
		val restriction = restrictions
			.filter(RelationRangeRestrictionAxiom)
			.filter[kind == RangeRestrictionKind::ALL && it.relation == relation]
			.head
		
		if (restriction !== null) {
			restriction.range
		} else {
			baseType
		}
	}
	
	private def String noteRelationRestrictions(Ontology context, Relation relation, Iterable<RelationRestrictionAxiom> restrictions) {
		if (relation !== null) {
			val description = restrictions
				.filter[it.relation == relation]
				.map[axiom|
					val domainOrRange = switch (relation) {
						ReverseRelation: "domain"
						ForwardRelation: "range"
					}
					switch (axiom) {
						RelationRangeRestrictionAxiom: {
							val restrictedTo = axiom.range
							if (axiom.kind == RangeRestrictionKind.ALL) {
								""
							} else {
								'''«domainOrRange» must include at least some «context.toBikeshedReference(restrictedTo)»'''
							}
						}
						RelationCardinalityRestrictionAxiom: {
							val kind = switch (axiom.kind) {
								case EXACTLY: "exactly"
								case MIN: "at least"
								case MAX: "at most"
							}
							'''cardinality restricted to «kind» «axiom.cardinality»'''
						}
						RelationTargetRestrictionAxiom: {
							'''«domainOrRange» restricted to instance «context.toBikeshedReference(axiom.target)»'''
						}
						default: axiom.toString
					}
					
				]
				.reject[empty]
				.toList
				.join(", ")
			if (!description.empty) {
				return "(" + description + ")"
			}
		}
		""
	}
}