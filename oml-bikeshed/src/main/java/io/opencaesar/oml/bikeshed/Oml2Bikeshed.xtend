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

import io.opencaesar.oml.AnnotationProperty
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptInstance
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
import io.opencaesar.oml.EnumeratedScalar
import io.opencaesar.oml.FacetedScalar
import io.opencaesar.oml.FeaturePredicate
import io.opencaesar.oml.ForwardRelation
import io.opencaesar.oml.Import
import io.opencaesar.oml.Member
import io.opencaesar.oml.NamedInstance
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.PropertyRestrictionAxiom
import io.opencaesar.oml.PropertyValueAssertion
import io.opencaesar.oml.RangeRestrictionKind
import io.opencaesar.oml.Relation
import io.opencaesar.oml.RelationCardinalityRestrictionAxiom
import io.opencaesar.oml.RelationEntity
import io.opencaesar.oml.RelationEntityPredicate
import io.opencaesar.oml.RelationInstance
import io.opencaesar.oml.RelationRangeRestrictionAxiom
import io.opencaesar.oml.RelationRestrictionAxiom
import io.opencaesar.oml.RelationTargetRestrictionAxiom
import io.opencaesar.oml.ReverseRelation
import io.opencaesar.oml.Rule
import io.opencaesar.oml.SameAsPredicate
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.ScalarPropertyCardinalityRestrictionAxiom
import io.opencaesar.oml.ScalarPropertyRangeRestrictionAxiom
import io.opencaesar.oml.ScalarPropertyRestrictionAxiom
import io.opencaesar.oml.ScalarPropertyValueAssertion
import io.opencaesar.oml.ScalarPropertyValueRestrictionAxiom
import io.opencaesar.oml.SpecializableTerm
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.StructuredPropertyCardinalityRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyRangeRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyRestrictionAxiom
import io.opencaesar.oml.StructuredPropertyValueAssertion
import io.opencaesar.oml.StructuredPropertyValueRestrictionAxiom
import io.opencaesar.oml.TypePredicate
import io.opencaesar.oml.Vocabulary
import io.opencaesar.oml.VocabularyBundle
import io.opencaesar.oml.VocabularyBundleExtension
import io.opencaesar.oml.VocabularyBundleInclusion
import io.opencaesar.oml.VocabularyExtension
import io.opencaesar.oml.util.OmlSearch
import java.util.ArrayList
import java.util.Collection
import org.eclipse.emf.common.util.URI

import static extension io.opencaesar.oml.bikeshed.OmlUtils.*
import static extension io.opencaesar.oml.util.OmlRead.*
import static extension io.opencaesar.oml.util.OmlSearch.*

/**
 * Transform OML to Bikeshed
 * 
 * To produce documentation for a given ontology in OML we use Bikeshed as an intermediate form
 * that can be leveraged to produce the html output from a simpler Markdown specification.
 * 
 * See: OML Reference https://opencaesar.github.io/oml/
 * See: Bikeshed Reference https://tabatkins.github.io/bikeshed/
 * 
 */
class Oml2Bikeshed {

	val Ontology contextOntology
	val OmlSearchContext context
	val String url
	val String relativePath

	new(Ontology contextOntology, OmlSearchContext context, String url, String relativePath) {
		this.contextOntology = contextOntology
		this.context = context
		this.url = url
		this.relativePath = relativePath
	}
	
	def String run() {
		contextOntology.toBikeshed
	}
	
	private def dispatch String toBikeshed(Element element) '''
	'''

	private def dispatch String toBikeshed(Ontology ontology) '''
		<pre class='metadata'>
		«ontology.toPre»
		</pre>
		«IF ontology.isDeprecated(context)»
		<div class=note>
		This ontology has been deprecated
		</div>
		«ENDIF»
		<div export=true>
		«ontology.toDiv»
		</div>
		<style>
		a[data-link-type=biblio] {
		    white-space: pre-wrap;
		}
		table.def th {
			white-space: nowrap;
		}
		table.def ul {
			padding-left: 1em;
		}
		table.def dfn code {
			font-family: sans-serif;
			color: #005A9C;
		}
		</style>
	'''
		
	private def String toPre(Ontology ontology) '''
		Title: «ontology.getTitle(context)»
		Shortname: «ontology.prefix»
		Level: 1
		Status: LS-COMMIT
		ED: «url»/«relativePath»
		Repository: «url»
		Editor: «ontology.getCreator(context).replaceAll(',', '')»
		!Copyright: «ontology.getCopyright(context)»
		Boilerplate: copyright no, conformance no
		Local Boilerplate: logo yes
		Markup Shorthands: markdown yes, css no
		Use Dfn Panels: yes
		External Infotrees: anchors.bsdata yes
		Abstract: «ontology.getDescription(context).replaceAll('\n', '\n ')»
	'''

	private def dispatch String toDiv(Vocabulary vocabulary) '''
		«vocabulary.toNamespace("# Namespace # {#Namespace}")»			
		«vocabulary.toImport("# Imports # {#Extensions}", VocabularyExtension)»
		«vocabulary.toStatement("# Aspects # {#Aspects}", Aspect)»
		«vocabulary.toStatement("# Concepts # {#concepts}", Concept)»
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
		«description.toStatement("# Concept Instances # {#ConceptInstances}", ConceptInstance)»
		«description.toStatement("# Relation Instances # {#RelationInstances}", RelationInstance)»
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
			* [«ontology.iri»](«ontologyURI»)  [«ontology.prefix»]
			
	'''
	
	private def <T extends Element> String toImport(Ontology ontology, String heading, Class<T>...types) '''
		«val elements = types.map[type|ontology.imports.filter(type)].flatten»
		«IF !elements.empty»
		«heading»
		«FOR element : elements»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''
	
	private def <T extends Member> String toStatement(Ontology ontology, String heading, Class<T>...types) '''
		«val elements = types.map[ontology.statements.filter(it)].flatten»
		«IF !elements.empty»
		«heading»
		«FOR element : elements.sortBy[name]»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''

	private def dispatch String toBikeshed(Import ^import) '''
		«val importURI = URI.createURI(^import.iri).trimFileExtension.appendFileExtension('html')»
			* [«^import.importedOntology?.iri»](«importURI»)«IF ^import.prefix !== null» [«^import.prefix»]«ENDIF»
	'''

	private def dispatch String toBikeshed(SpecializableTerm term) '''
		«term.sectionHeader»
		
		«term.getComment(context)»
		
		«term.plainDescription»
		
		<table class='def'>
		«val superTerms = term.findSuperTerms.filter[t|context.contains(t)]»
		«IF !superTerms.empty»
			«defRow('Super terms', superTerms.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(term.ontology)»</a>'''].toUL)»
		«ENDIF»
		«val subTerms = term.findSubTerms.filter[t|context.contains(t)]»
		«IF !subTerms.empty»
			«defRow('Sub terms', subTerms.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(term.ontology)»</a>'''].toUL)»
		«ENDIF»		
		</table>
		
	'''

	private def dispatch String toBikeshed(Entity entity) '''
		«entity.sectionHeader»
		
		«entity.getComment(context)»
		
		«entity.plainDescription»
		
		<table class='def'>
		«IF entity instanceof RelationEntity»
			«val source = entity.source»
			«defRow('Source', '''<a spec="«source.ontology.iri»" lt="«source.name»">«source.getReferenceName(entity.ontology)»</a>''')»

			«val target = entity.target»
			«defRow('Target', '''<a spec="«target.ontology.iri»" lt="«target.name»">«target.getReferenceName(entity.ontology)»</a>''')»
			
		«ENDIF»
		
	
		«val superEntities = entity.findSuperTerms.filter[t|context.contains(t)]»
		«IF !superEntities.empty»
			«defRow('Supertypes', superEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].toUL)»
		«ENDIF»
		
		«val subEntities = entity.findSubTerms.filter(Entity).filter[t|context.contains(t)]»
		«IF !subEntities.empty»
			«defRow('Subtypes', subEntities.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].toUL)»
		«ENDIF»
		
		«IF entity instanceof RelationEntity»
		
			«IF entity.forwardRelation !== null»
				«defRow('Forward relation', '''
					«IF entity.forwardRelation.name.toLowerCase != entity.name.toLowerCase»
					<dfn>«entity.forwardRelation.name»</dfn>
					«ELSE»
					«entity.forwardRelation.name»
					«ENDIF»
					«val relationDescription = entity.forwardRelation.getDescription(context)»
					«IF !relationDescription.empty»
						<p>«relationDescription»</p>
					«ENDIF»
				''')»
			«ENDIF»
			
			«IF entity.reverseRelation !== null»
				«defRow('Reverse relation', '''
					«IF entity.reverseRelation.name.toLowerCase != entity.name.toLowerCase»
					<dfn>«entity.reverseRelation.name»</dfn>
					«ELSE»
					«entity.reverseRelation.name»
					«ENDIF»
					«val relationDescription = entity.reverseRelation.getDescription(context)»
					«IF !relationDescription.empty»
						<p>«relationDescription»</p>
					«ENDIF»
				''')»
			«ENDIF»
			
			«val attr=entity.relationshipAttributes»
			«IF attr !== null»
				«defRow('Attributes', attr)»
			«ENDIF»
						
			
		«ENDIF»
		
		«val propertyRestrictions = entity.findPropertyRestrictions.filter[r|context.contains(r)].toList»

		«val propertiesDirect = OmlSearch.findSemanticPropertiesWithDomain(entity).filter[p|context.contains(p)]»
		«val propertiesWithRestrictions = propertyRestrictions.map[restrictedFeature] »
		«val properties = (propertiesDirect + propertiesWithRestrictions).toSet»

		«IF !properties.empty »
			«defRow('Properties', properties.sortBy[name].map[getPropertyDescription(entity.ontology, propertyRestrictions)].toUL)»
		«ENDIF»

		«val keys = entity.findKeys.filter[k|context.contains(k)]»
		«IF !keys.empty»
			«defRow('Keys', keys.map[k|k.properties.sortBy[name].map['''<a spec="«ontology.iri»" lt="«name»">«getReferenceName(entity.ontology)»</a>'''].join(', ')].toUL)»
		«ENDIF»
		
		«val relationRestrictions = entity.findRelationRestrictions.filter[r|context.contains(r)].toList»

		«val domainRelationsDirect = entity.findSourceRelations.filter[e|context.contains(e)]»
		«val domainRelationsWithRangeRestrictions = relationRestrictions.map[relation].filter(ForwardRelation) »
		«val domainRelations = (domainRelationsDirect + domainRelationsWithRangeRestrictions).toSet »
		
		«IF !domainRelations.empty »
			«defRow('Source relations', domainRelations.sortBy[name].map[r|'''
				«r.toBikeshedReference(entity.ontology)» («entity.name» → «getRestrictedType(r, r.range, entity.ontology, relationRestrictions).toBikeshedReference(entity.ontology)») «entity.ontology.noteRelationRestrictions(r, relationRestrictions)»
			'''].toUL)»
		«ENDIF»
		
		«val rangeRelationsDirect = entity.findTargetRelations.filter[e|context.contains(e)]»
		«val rangeRelationsWithDomainRestrictions = relationRestrictions.map[relation].filter(ReverseRelation)»
		«val rangeRelations = (rangeRelationsDirect + rangeRelationsWithDomainRestrictions).toSet»

		«IF !rangeRelations.empty »
			«defRow('Target relations', rangeRelations.sortBy[name].map[r|'''
				«r.toBikeshedReference(entity.ontology)» («getRestrictedType(r, r.domain, entity.ontology, relationRestrictions).toBikeshedReference(entity.ontology)» → «entity.name») «entity.ontology.noteRelationRestrictions(r, relationRestrictions)»
			'''].toUL)»
		«ENDIF»
		</table>
		
	'''
		
	// FacetedScalar
	private def dispatch String toBikeshed(FacetedScalar scalar) '''
		«scalar.sectionHeader»
		
		«scalar.getComment(context)»
		
		«scalar.plainDescription»
		
		<table class='def'>
		«IF null!==scalar.length»«defRow('length', scalar.length.toString)»«ENDIF»
		«IF null!==scalar.minLength»«defRow('min length', scalar.minLength.toString)»«ENDIF»
		«IF null!==scalar.maxLength»«defRow('max length', scalar.maxLength.toString)»«ENDIF»
		«IF null!==scalar.pattern»«defRow('pattern', scalar.pattern.toString)»«ENDIF»
		«IF null!==scalar.language»«defRow('language', scalar.language.toString)»«ENDIF»
		«IF null!==scalar.minInclusive»«defRow('min inclusive', scalar.minInclusive.stringValue)»«ENDIF»
		«IF null!==scalar.minExclusive»«defRow('min exclusive', scalar.minExclusive.stringValue)»«ENDIF»
		«IF null!==scalar.maxInclusive»«defRow('max inclusive', scalar.maxInclusive.stringValue)»«ENDIF»
		«IF null!==scalar.maxExclusive»«defRow('max exclusive', scalar.maxExclusive.stringValue)»«ENDIF»
		</table>
	'''
	
	// EnumerationScalar
	private def dispatch String toBikeshed(EnumeratedScalar scalar) '''
		«scalar.sectionHeader»
		
		«scalar.getComment(context)»
		
		«scalar.plainDescription»
		
		<table class='def'>
			«defRow('Values', scalar.literals.map[stringValue].toUL)»
		</table>
		
	'''

	private def dispatch String toBikeshed(AnnotationProperty property) '''
		«property.sectionHeader»
		
		«property.getComment(context)»

		«property.plainDescription»
		
	'''
	
	private def dispatch String toBikeshed(ScalarProperty property) '''
		«property.sectionHeader»
		
		«property.getComment(context)»
		
		«property.plainDescription»
		
		<table class='def'>
			«val domain = property.domain»
			«defRow('Domain', '''<a spec="«domain.ontology?.iri»" lt="«domain.name»">«domain.getReferenceName(domain.ontology)»</a>''')»
	
			«val range = property.range»
			«defRow('Range', '''<a spec="«range.ontology?.iri»" lt="«range.name»">«range.getReferenceName(range.ontology)»</a>''')»
			
			«IF property.functional»
				«defRow('Attributes', 'Functional')»
			«ENDIF»
		</table>
		
	'''

  	//TODO: find an ontology containing examples of this we can test against
	private def dispatch String toBikeshed(StructuredProperty property) '''
		«property.sectionHeader»
		
		«property.getComment(context)»
		
		«property.plainDescription»
		
	'''
		
	// Inference rules have a set of set of antecedents and one consequent
	private def dispatch String toBikeshed(Rule rule) '''
		«rule.sectionHeader»
		
		«rule.antecedent.map[toBikeshed].join(" ∧ ")» -> «rule.consequent.map[toBikeshed].join(" ∧ ")»
	'''
	
	private def dispatch String toBikeshed(TypePredicate predicate) '''
		«predicate.type.name»(«oneOf(predicate.variable)»)
	'''
		
	private def dispatch String toBikeshed(RelationEntityPredicate predicate) '''
		«predicate.entity.name»(«oneOf(predicate.variable1)», «oneOf(predicate.entityVariable)», «oneOf(predicate.variable2, predicate.instance2)»)
	'''
	
	private def dispatch String toBikeshed(FeaturePredicate predicate) '''
		«predicate.feature.name»(«oneOf(predicate.variable1)», «oneOf(predicate.variable2, predicate.instance2, predicate.literal2)»)
	'''

    private def dispatch String toBikeshed(SameAsPredicate predicate) '''
        sameAs(«oneOf(predicate.variable1)», «oneOf(predicate.variable2, predicate.instance2)»)
    '''

    private def dispatch String toBikeshed(DifferentFromPredicate predicate) '''
        differentFrom(«oneOf(predicate.variable1)», «oneOf(predicate.variable2, predicate.instance2)»)
    '''
	
	private def String oneOf(Object... options) {
		return options.stream.filter[o | o !== null].findFirst.get.toString()
	}
	
	private def dispatch String toBikeshed(NamedInstance instance) '''
		«instance.sectionHeader»
		
		«instance.getComment(context)»
		
		«instance.plainDescription»
		
		«val types = switch (instance) {
			ConceptInstance: instance.findTypeAssertions.map[type].filter[t|context.contains(t)].sortBy[name]
			RelationInstance: instance.findTypeAssertions.map[type].filter[t|context.contains(t)].sortBy[name]
		}»
		«val scope = instance.ontology»
		
		<table class='def'>
		«IF !types.empty»
			«defRow('Types', types.map[toBikeshedReference(scope)].toUL)»
		«ENDIF»
		«IF instance instanceof RelationInstance»
			«IF !instance.sources.empty»
				«defRow('Source', instance.sources.map[toBikeshedReference(scope)].toUL)»
			«ENDIF»
			«IF !instance.targets.empty»
				«defRow('Target', instance.targets.map[toBikeshedReference(scope)].toUL)»
			«ENDIF»
		«ENDIF»
		«val propertyValueAssertions = instance.findPropertyValueAssertions.filter[a|context.contains(a)].sortBy[property.name]»
		«IF !propertyValueAssertions.empty»
			«defRow('Properties', propertyValueAssertions.map[scope.toBikeshedPropertyValue(it)].toUL)»
		«ENDIF»
		«val linkAssertions = instance.findLinkAssertions.filter[a|context.contains(a)].sortBy[relation.name]»
		«IF !linkAssertions.empty»
			«defRow('Links', linkAssertions.map[relation.toBikeshedReference(scope) + ' ' + target.toBikeshedReference(scope)].toUL)»
		«ENDIF»
		</table>
	'''
	
	//----------------------------------------------------------------------------------------------------------

	private static def String getRelationshipAttributes(RelationEntity entity) {
		val ArrayList<String> pnames=new ArrayList
		if (entity.functional) pnames.add("Functional")
		if (entity.inverseFunctional) pnames.add("InverseFunctional")
		if (entity.symmetric) pnames.add("Symmetric")
		if (entity.asymmetric) pnames.add("Asymmetric")
		if (entity.reflexive) pnames.add("Reflexive")
		if (entity.irreflexive) pnames.add("Irreflexive")
		if (entity.transitive) pnames.add("Transitive")
		pnames.toUL
	}
	
	private static def String toBikeshedReference(Member member, Ontology scope) 
	'''<a spec="«member.ontology.iri»" lt="«member.name»">«member.getReferenceName(scope)»</a>'''
	
	private static def String toBikeshedPropertyValue(Ontology scope, PropertyValueAssertion assertion) {
		val valueText = switch (assertion) {
			ScalarPropertyValueAssertion: 
				assertion.value.lexicalValue
			StructuredPropertyValueAssertion: '''
				«assertion.value.type.toBikeshedReference(scope)»
				«FOR subAssertion : assertion.value.ownedPropertyValues»
					* «scope.toBikeshedPropertyValue(subAssertion)»
				«ENDFOR»
			'''
		}
		'''
		«assertion.property.toBikeshedReference(scope)» = «valueText»'''
	}
	
	private def String getPlainDescription(Member member) '''
		«IF member.isDeprecated(context)»
		<div class=note>
		This ontology member has been deprecated
		</div>
		«ENDIF»
		«val desc=member.getDescription(context)»
		«IF !desc.startsWith("http")»
		«desc»
		«ENDIF»
	'''
	
	/**
	 * Tricky bit: if description starts with a url we treat it as an
	 * external definition.
	 */
	private def String getSectionHeader(Member member) {
		val desc=member.getDescription(context)

		if (desc.startsWith("http"))
		'''## <dfn>«member.name»</dfn> see \[«member.name»](«desc») ## {#«member.name.toFirstUpper»}'''
		else
		'''## <dfn>«member.name»</dfn> ## {#«member.name.toFirstUpper»}'''
	}
	
	private static def String getReferenceName(Member member, Ontology ontology) {
		val localName = member.getAbbreviatedIriIn(ontology)
		localName ?: member.abbreviatedIri
	}
	
	private dispatch static def String getPropertyDescription(ScalarProperty property, Ontology context, Collection<PropertyRestrictionAxiom> restrictions) {
		val baseDescription = '''<a spec="«property.ontology.iri»" lt="«property.name»">«property.getReferenceName(context)»</a>'''
		
		val restrictionDescriptions = restrictions
			.filter(ScalarPropertyRestrictionAxiom)
			.filter[it.property == property]
			.map[axiom|
				switch (axiom) {
					ScalarPropertyRangeRestrictionAxiom: {
						val range = axiom.range
						if (axiom.kind == RangeRestrictionKind.ALL) {
							'''must be of type «range.toBikeshedReference(context)»'''
						} else {
							'''must include instance of «range.toBikeshedReference(context)»'''
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
						'''must have value «axiom.value.stringValue»'''
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
	
	private static dispatch def String getPropertyDescription(StructuredProperty property, Ontology context, Collection<PropertyRestrictionAxiom> restrictions) {
		val baseDescription = '''<a spec="«property.ontology.iri»" lt="«property.name»">«property.getReferenceName(context)»</a>'''
		
		val restrictionDescriptions = restrictions
			.filter(StructuredPropertyRestrictionAxiom)
			.filter[it.property == property]
			.map[axiom|
				switch (axiom) {
					StructuredPropertyRangeRestrictionAxiom: {
						val range = axiom.range
						if (axiom.kind == RangeRestrictionKind.ALL) {
							'''must be of type «range.toBikeshedReference(context)»'''
						} else {
							'''must include at least some «range.toBikeshedReference(context)»'''
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
	
	private static def Entity getRestrictedType(Relation relation, Entity baseType, Ontology context, Collection<RelationRestrictionAxiom> restrictions) {
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
	
	private static def String noteRelationRestrictions(Ontology context, Relation relation, Collection<RelationRestrictionAxiom> restrictions) {
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
								'''«domainOrRange» must include at least some «restrictedTo.toBikeshedReference(context)»'''
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
							'''«domainOrRange» restricted to instance «axiom.target.toBikeshedReference(context)»'''
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
	
	private static def String defRow(String header, String content) '''
		<tr>
			<th>«header»</th>
			<td>
				«content»
			</td>
		</tr>
	'''
	
	
	private static def String toUL(Iterable<String> items) '''
		<ul>
			«FOR item : items»
			<li>
				«item»
			</li>
			«ENDFOR»
		</ul>
	'''
	
}