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
import io.opencaesar.oml.AnonymousRelationInstance
import io.opencaesar.oml.Argument
import io.opencaesar.oml.Aspect
import io.opencaesar.oml.Concept
import io.opencaesar.oml.ConceptInstance
import io.opencaesar.oml.Description
import io.opencaesar.oml.DescriptionBundle
import io.opencaesar.oml.DifferentFromPredicate
import io.opencaesar.oml.Element
import io.opencaesar.oml.Entity
import io.opencaesar.oml.Import
import io.opencaesar.oml.Literal
import io.opencaesar.oml.Member
import io.opencaesar.oml.NamedInstance
import io.opencaesar.oml.Ontology
import io.opencaesar.oml.PropertyCardinalityRestrictionAxiom
import io.opencaesar.oml.PropertyPredicate
import io.opencaesar.oml.PropertyRangeRestrictionAxiom
import io.opencaesar.oml.PropertyRestrictionAxiom
import io.opencaesar.oml.PropertySelfRestrictionAxiom
import io.opencaesar.oml.PropertyValueAssertion
import io.opencaesar.oml.PropertyValueRestrictionAxiom
import io.opencaesar.oml.RangeRestrictionKind
import io.opencaesar.oml.RelationEntity
import io.opencaesar.oml.RelationEntityPredicate
import io.opencaesar.oml.RelationInstance
import io.opencaesar.oml.Rule
import io.opencaesar.oml.SameAsPredicate
import io.opencaesar.oml.Scalar
import io.opencaesar.oml.ScalarEquivalenceAxiom
import io.opencaesar.oml.ScalarProperty
import io.opencaesar.oml.SemanticProperty
import io.opencaesar.oml.SpecializableTerm
import io.opencaesar.oml.Structure
import io.opencaesar.oml.StructureInstance
import io.opencaesar.oml.StructuredProperty
import io.opencaesar.oml.Type
import io.opencaesar.oml.TypePredicate
import io.opencaesar.oml.Vocabulary
import io.opencaesar.oml.VocabularyBundle
import io.opencaesar.oml.util.OmlSearch
import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.Set
import java.util.stream.Collectors
import java.util.stream.IntStream
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource

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
package class Oml2Bikeshed {

	val Ontology contextOntology
	val Set<Resource> scope
	val String url
	val String relativePath

	new(Ontology contextOntology, Set<Resource> scope, String url, String relativePath) {
		this.contextOntology = contextOntology
		this.scope = scope
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
		«IF ontology.findIsDeprecated(scope)»
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
		Title: «ontology.findTitle(scope)»
		Shortname: «ontology.prefix»
		Level: 1
		Status: LS-COMMIT
		ED: «url»/«relativePath»
		Repository: «url»
		Editor: «ontology.findCreator(scope).replaceAll(',', '')»
		!Copyright: «ontology.findCopyright(scope)»
		Boilerplate: copyright no, conformance no
		Local Boilerplate: logo yes
		Markup Shorthands: markdown yes, css no
		Use Dfn Panels: yes
		Complain About: mixed-indents no
		External Infotrees: anchors.bsdata yes
		Abstract: «ontology.findDescription(scope).replaceAll('\n', '\n ')»
	'''

	private def dispatch String toDiv(Vocabulary vocabulary) '''
		«vocabulary.toNamespace("# Namespace # {#Namespace}")»			
		«vocabulary.toImport("# Imports # {#Imports}")»
		«vocabulary.toStatement("# Aspects # {#Aspects}", Aspect)»
		«vocabulary.toStatement("# Concepts # {#concepts}", Concept)»
		«vocabulary.toStatement("# Relation Entities # {#Relations}", RelationEntity)»
		«vocabulary.toStatement("# Structures # {#Structures}", Structure)»
		«vocabulary.toStatement("# Scalars # {#Scalars}", Scalar)»
		«vocabulary.toStatement("# Annotation Properties # {#AnnotationProperties}", AnnotationProperty)»
		«vocabulary.toStatement("# Structured Properties # {#StructuredProperties}", StructuredProperty)»
		«vocabulary.toStatement("# Scalar Properties # {#ScalarProperties}", ScalarProperty)»
		«vocabulary.toStatement("# Rules # {#Rules}", Rule)»
	'''
	
	private def dispatch String toDiv(VocabularyBundle bundle) '''
		«bundle.toNamespace("# Namespace # {#Namespace}")»			
		«bundle.toImport("# Imports # {#Imports}")»
	'''

	private def dispatch String toDiv(Description description) '''
		«description.toNamespace("# Namespace # {#Namespace}")»
		«description.toImport("# Imports # {#Imports}")»
		«description.toStatement("# Concept Instances # {#ConceptInstances}", ConceptInstance)»
		«description.toStatement("# Relation Instances # {#RelationInstances}", RelationInstance)»
	'''

	private def dispatch String toDiv(DescriptionBundle bundle) '''
		«bundle.toNamespace("# Namespace # {#Namespace}")»			
		«bundle.toImport("# Imports # {#Imports}")»
	'''

	// FIXME: this works for internal links to generated docs but not for links to external documentation. 
	private def String toNamespace(Ontology ontology, String heading) '''
		«heading»
		«val ontologyURI = ontology.eResource.URI.trimFileExtension.appendFileExtension('html').lastSegment»
			* [«ontology.iri»](«ontologyURI»)  [«ontology.prefix»]
			
	'''
	
	private def <T extends Import> String toImport(Ontology ontology, String heading) '''
		«val elements = ontology.ownedImports»
		«IF !elements.empty»
		«heading»
		«FOR element : elements»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''
	
	private def <T extends Member> String toStatement(Ontology ontology, String heading, Class<T> type) '''
		«val elements = ontology.statements.filter[!isRef].filter(type)»
		«IF !elements.empty»
		«heading»
		«FOR element : elements.sortBy[abbreviatedIri]»
		«element.toBikeshed»
		
		«ENDFOR»
		«ENDIF»
	'''

	private def dispatch String toBikeshed(Import ^import) '''
		«val n = URI.createURI(contextOntology.iri).segmentCount»
		«val relativePath = IntStream.range(0, n).mapToObj(i| "../").collect(Collectors.joining(""))»
		«var importURI = URI.createURI(^import.iri).appendFileExtension('html')»
		«var importPath = relativePath + importURI.host + importURI.path»
			* [«^import.importedOntology?.iri»](«importPath»)«IF ^import.prefix !== null» [«^import.prefix»]«ENDIF»
	'''

	private def dispatch String toBikeshed(SpecializableTerm term) '''
		«term.sectionHeader»
		
		«term.findComment(scope)»
		
		«term.plainDescription»
		
		<table class='def'>
		«val superTerms = term.findSuperTerms(scope)»
		«IF !superTerms.empty»
			«defRow('Super terms', superTerms.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
		«ENDIF»
		«val subTerms = term.findSubTerms(scope)»
		«IF !subTerms.empty»
			«defRow('Sub terms', subTerms.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
		«ENDIF»		
		</table>
		
	'''

	private def dispatch String toBikeshed(Entity entity) '''
		«entity.sectionHeader»
		
		«entity.findComment(scope)»
		
		«entity.plainDescription»
		
		<table class='def'>
		«IF entity instanceof RelationEntity»
			«val sources = entity.findSources(scope)»
			«defRow('Sources', sources.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»

			«val targets = entity.findTargets(scope)»
			«defRow('Targets', targets.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
			
		«ENDIF»
		
	
		«val superEntities = entity.findSuperTerms(scope)»
		«IF !superEntities.empty»
			«defRow('Supertypes', superEntities.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
		«ENDIF»
		
		«val subEntities = entity.findSubTerms(scope).filter(Entity)»
		«IF !subEntities.empty»
			«defRow('Subtypes', subEntities.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
		«ENDIF»
		
		«IF entity instanceof RelationEntity»
		
			«IF entity.forwardRelation !== null»
				«defRow('Forward relation', '''
					<dfn lt="«entity.forwardRelation.dfn»">«entity.forwardRelation.name»</dfn>
					«val relationDescription = entity.forwardRelation.findDescription(scope)»
					«IF !relationDescription.empty»
						<p>«relationDescription»</p>
					«ENDIF»
				''')»
			«ENDIF»
			
			«IF entity.reverseRelation !== null»
				«defRow('Reverse relation', '''
					<dfn lt="«entity.reverseRelation.dfn»">«entity.reverseRelation.name»</dfn>
					«val relationDescription = entity.reverseRelation.findDescription(scope)»
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
		
		«val propertyRestrictions = entity.findPropertyRestrictionAxioms(scope).toList»
		«val propertiesDirect = findSemanticPropertiesWithDomain(entity, scope)»
		«val propertiesWithRestrictions = propertyRestrictions.map[property] »
		«val properties = (propertiesDirect + propertiesWithRestrictions).toSet»

		«IF !properties.empty »
			«defRow('Properties', properties.sortBy[abbreviatedIri].map[getPropertyDescription(propertyRestrictions)].toUL)»
		«ENDIF»

		«val keys = entity.findKeyAxioms(scope)»
		«IF !keys.empty»
			«defRow('Keys', keys.map[k|k.properties.sortBy[abbreviatedIri].map[toBikeshedReference].join(', ')].toUL)»
		«ENDIF»
		
		«IF entity instanceof Concept»
			«val instances = entity.findInstanceEnumerationAxioms(scope).flatMap[instances]»
			«IF !instances.isEmpty»
				«defRow('Instances', instances.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
			«ENDIF»
		«ENDIF»
		</table>
		
	'''
	
	// FacetedScalar
	private def dispatch String toBikeshed(Scalar scalar) '''
		«scalar.sectionHeader»
		
		«scalar.findComment(scope)»
		
		«scalar.plainDescription»
		
		<table class='def'>

		«val superScalars = scalar.findSuperTerms(scope)»
		«IF !superScalars.empty»
			«defRow('Supertypes', superScalars.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
		«ENDIF»
		
		«val subScalars = scalar.findSubTerms(scope).filter(Scalar)»
		«IF !subScalars.empty»
			«defRow('Subtypes', subScalars.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
		«ENDIF»

		«val equivalenceAxioms = scalar.findScalarEquivalenceAxiomsWithSubScalar(scope)»
		«IF !equivalenceAxioms.empty»
			«defRow('Equivalents', equivalenceAxioms.sortBy[superScalar.abbreviatedIri].map[toBikeshed].toUL)»
		«ENDIF»

		«val literals = scalar.findLiteralEnumerationAxioms(scope).flatMap[literals]»
		«IF !literals.empty»
			«defRow('One of', literals.sortBy[stringValue].map[stringValue].toUL)»
		«ENDIF»
		</table>
	'''

	private def dispatch String toBikeshed(ScalarEquivalenceAxiom axiom) '''
		«axiom.subScalar.toBikeshedReference»«IF axiom.numberOfFacets > 0»(
		«IF null!==axiom.length»«defRow('length', axiom.length.toString)»«ENDIF»
		«IF null!==axiom.minLength»«defRow('min length', axiom.minLength.toString)»«ENDIF»
		«IF null!==axiom.maxLength»«defRow('max length', axiom.maxLength.toString)»«ENDIF»
		«IF null!==axiom.pattern»«defRow('pattern', axiom.pattern.toString)»«ENDIF»
		«IF null!==axiom.language»«defRow('language', axiom.language.toString)»«ENDIF»
		«IF null!==axiom.minInclusive»«defRow('min inclusive', axiom.minInclusive.stringValue)»«ENDIF»
		«IF null!==axiom.minExclusive»«defRow('min exclusive', axiom.minExclusive.stringValue)»«ENDIF»
		«IF null!==axiom.maxInclusive»«defRow('max inclusive', axiom.maxInclusive.stringValue)»«ENDIF»
		«IF null!==axiom.maxExclusive»«defRow('max exclusive', axiom.maxExclusive.stringValue)»«ENDIF»
		)«ENDIF»
	'''
	
	private def dispatch String toBikeshed(AnnotationProperty property) '''
		«property.sectionHeader»
		
		«property.findComment(scope)»

		«property.plainDescription»
		
	'''

	private def dispatch String toBikeshed(ScalarProperty property) '''
		«property.sectionHeader»
		
		«property.findComment(scope)»
		
		«property.plainDescription»
		
		<table class='def'>
			«val domains = property.domains»
			«defRow('Domains', domains.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
	
			«val ranges = property.ranges»
			«defRow('Ranges', ranges.sortBy[abbreviatedIri].map[toBikeshedReference].toUL)»
			
			«IF property.functional»
				«defRow('Attributes', 'Functional')»
			«ENDIF»
		</table>
		
	'''

	// Inference rules have a set of set of antecedents and one consequent
	private def dispatch String toBikeshed(Rule rule) '''
		«rule.sectionHeader»
		
		«rule.antecedent.map[toBikeshed].join(" ∧ ")» -> «rule.consequent.map[toBikeshed].join(" ∧ ")»
	'''
	
	private def dispatch String toBikeshed(TypePredicate predicate) '''
		«predicate.type.name»(«predicate.argument.toBikeshed»)
	'''
		
	private def dispatch String toBikeshed(RelationEntityPredicate predicate) '''
		«predicate.type.name»(«predicate.argument1.toBikeshed», «predicate.argument.toBikeshed», «predicate.argument2.toBikeshed»)
	'''
	
	private def dispatch String toBikeshed(PropertyPredicate predicate) '''
		«predicate.property.name»(«predicate.argument1.toBikeshed», «predicate.argument2.toBikeshed»)
	'''

    private def dispatch String toBikeshed(SameAsPredicate predicate) '''
		sameAs(«predicate.argument1.toBikeshed», «predicate.argument2.toBikeshed»)
    '''

    private def dispatch String toBikeshed(DifferentFromPredicate predicate) '''
        differentFrom(«predicate.argument1.toBikeshed», «predicate.argument2.toBikeshed»)
    '''
	
	private def dispatch String toBikeshed(Argument argument) {
		if (argument.literal !== null)
			return argument.literal.lexicalValue
		else if (argument.instance !== null)
			return argument.instance.abbreviatedIri
		else if (argument.variable !== null)
			return argument.variable
	}

  	//TODO: find an ontology containing examples of this we can test against
	private def dispatch String toBikeshed(StructuredProperty property) '''
		«property.sectionHeader»
		
		«property.findComment(scope)»
		
		«property.plainDescription»
		
	'''
		
	private def dispatch String toBikeshed(NamedInstance instance) '''
		«instance.sectionHeader»
		
		«instance.findComment(scope)»
		
		«instance.plainDescription»
		
		«val types = switch (instance) {
			ConceptInstance: instance.findTypeAssertions(scope).map[type].sortBy[abbreviatedIri]
			RelationInstance: instance.findTypeAssertions(scope).map[type].sortBy[abbreviatedIri]
		}»
		
		<table class='def'>
		«IF !types.empty»
			«defRow('Types', types.map[toBikeshedReference].toUL)»
		«ENDIF»
		«IF instance instanceof RelationInstance»
			«IF !instance.sources.empty»
				«defRow('Source', instance.sources.map[toBikeshedReference].toUL)»
			«ENDIF»
			«IF !instance.targets.empty»
				«defRow('Target', instance.targets.map[toBikeshedReference].toUL)»
			«ENDIF»
		«ENDIF»
		«val propertyValueAssertions = instance.findPropertyValueAssertionsWithSubject(scope).sortBy[property.abbreviatedIri]»
		«IF !propertyValueAssertions.empty»
			«defRow('Properties', propertyValueAssertions.map[toBikeshedPropertyValue].toUL)»
		«ENDIF»
		</table>
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
		pnames.toUL
	}
	
	private def String toBikeshedReference(Member member) 
	'''<a spec="«member.ontology.iri»" lt="«member.dfn»">«member.getReferenceName»</a>'''
	
	private def String toBikeshedPropertyValue(PropertyValueAssertion assertion) {
		val valueTexts = assertion.value.map[value | 
			switch (value) {
				Literal: 
					value.lexicalValue
				StructureInstance: '''
					«value.structure.toBikeshedReference»
					«FOR subAssertion : value.ownedPropertyValues»
						* «subAssertion.toBikeshedPropertyValue»
					«ENDFOR»
				'''
				AnonymousRelationInstance: '''
					«value.relationEntity.toBikeshedReference»
					«FOR subAssertion : value.ownedPropertyValues»
						* «subAssertion.toBikeshedPropertyValue»
					«ENDFOR»
				'''
				NamedInstance: 
					value.toBikeshedReference
			}
		]
		
		'''
		«assertion.property.toBikeshedReference» «valueTexts.join(", ")»'''
	}
	
	private def String getPlainDescription(Member member) '''
		«IF member.findIsDeprecated(scope)»
		<div class=note>
		This ontology member has been deprecated
		</div>
		«ENDIF»
		«val desc=member.findDescription(scope)»
		«IF !desc.startsWith("http")»
		«desc»
		«ENDIF»
	'''
	
	/**
	 * Tricky bit: if description starts with a url we treat it as an
	 * external definition.
	 */
	private def String getSectionHeader(Member member) {
		val desc=member.findDescription(scope)

		if (desc.startsWith("http"))
		'''## <dfn lt="«member.dfn»">«member.name»</dfn> see \[«member.name»](«desc») ## {#«member.name.toFirstUpper»}'''
		else
		'''## <dfn lt="«member.dfn»">«member.name»</dfn> ## {#«member.name.toFirstUpper»}'''
	}
	
	private def String getReferenceName(Member member) {
		val localName = member.getAbbreviatedIriIn(contextOntology)
		localName ?: member.abbreviatedIri
	}
	
	private def String getPropertyDescription(SemanticProperty property, Collection<PropertyRestrictionAxiom> restrictions) {
		val baseDescription = property.toBikeshedReference + ' : ' + property.getRestrictedTypes(restrictions).map[toBikeshedReference].toCommaSeparated
		
		val restrictionDescriptions = restrictions
			.filter[it.property == property]
			.map[axiom|
				switch (axiom) {
					PropertyRangeRestrictionAxiom: {
						val range = axiom.range
						if (axiom.kind == RangeRestrictionKind.SOME) {
							'''must include instance of «range.toBikeshedReference»'''
						} else {
							'''''' // already acounted for in the property range above
						}
					}
					PropertyCardinalityRestrictionAxiom: {
						val kind = switch (axiom.kind) {
							case EXACTLY: "exactly"
							case MIN: "at least"
							case MAX: "at most"
						}
						'''must have «kind» «axiom.cardinality» «axiom.range.toBikeshedReference»'''
					}
					PropertyValueRestrictionAxiom: {
						'''must have the value «axiom.value.asString»'''
					}
					PropertySelfRestrictionAxiom: {
						'''must have a self reference'''
					}
					default: axiom.toString
				}
				
			]
			.reject[empty]
			.toList
			.join(", ")
			
		if (restrictionDescriptions.empty) {
			baseDescription
		} else {
			baseDescription + " (" + restrictionDescriptions + ")"
		}
	}

	private def Iterable<Type> getRestrictedTypes(SemanticProperty property, Collection<PropertyRestrictionAxiom> restrictions) {
		val restriction = restrictions
			.filter(PropertyRangeRestrictionAxiom)
			.filter[it.property == property]
			.filter[it.kind == RangeRestrictionKind::ALL]
			.head
		
		if (restriction !== null) {
			Collections.singletonList(restriction.range)
		} else {
			OmlSearch.findRanges(property, scope)
		}
	}

	//----------------

	private static def String asString(Element value) {
		if (value instanceof Literal)
			return value.lexicalValue
		else if (value instanceof StructureInstance)
			return value.structure.name + '[...]'
		else if (value instanceof AnonymousRelationInstance)
			return value.relationEntity.name + '[...]'
		else if (value instanceof Member)
			return value.abbreviatedIri 
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

	private static def String toCommaSeparated(Iterable<String> items) '''
		«FOR item : items SEPARATOR ","»«item»«ENDFOR»
	'''

	def static String getDfn(Member member) {
		val name = member.name.toLowerCase
		val members = member.ontology.members.filter[it.name.toLowerCase == name].toList
		val index = members.indexOf(member)
		return (index === 0) ? name : name+"_"+index
	}
	
}