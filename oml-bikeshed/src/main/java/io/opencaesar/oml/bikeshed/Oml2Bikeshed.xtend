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
import java.util.stream.Collectors
import java.util.stream.IntStream
import org.eclipse.emf.common.util.URI

import static extension io.opencaesar.oml.bikeshed.OmlUtils.*
import static extension io.opencaesar.oml.util.OmlRead.*
import static extension io.opencaesar.oml.util.OmlSearch.*
import io.opencaesar.oml.ScalarEquivalenceAxiom

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
		
		«term.getComment(context)»
		
		«term.plainDescription»
		
		<table class='def'>
		«val superTerms = term.findSuperTerms.filter[t|context.contains(t)]»
		«IF !superTerms.empty»
			«defRow('Super terms', superTerms.sortBy[abbreviatedIri].map[toBikeshedReference(term.ontology)].toUL)»
		«ENDIF»
		«val subTerms = term.findSubTerms.filter[t|context.contains(t)]»
		«IF !subTerms.empty»
			«defRow('Sub terms', subTerms.sortBy[abbreviatedIri].map[toBikeshedReference(term.ontology)].toUL)»
		«ENDIF»		
		</table>
		
	'''

	private def dispatch String toBikeshed(Entity entity) '''
		«entity.sectionHeader»
		
		«entity.getComment(context)»
		
		«entity.plainDescription»
		
		<table class='def'>
		«IF entity instanceof RelationEntity»
			«val sources = entity.findSources.filter[t|context.contains(t)]»
			«defRow('Sources', sources.sortBy[abbreviatedIri].map[toBikeshedReference(entity.ontology)].toUL)»

			«val targets = entity.findTargets.filter[t|context.contains(t)]»
			«defRow('Targets', targets.sortBy[abbreviatedIri].map[toBikeshedReference(entity.ontology)].toUL)»
			
		«ENDIF»
		
	
		«val superEntities = entity.findSuperTerms.filter[t|context.contains(t)]»
		«IF !superEntities.empty»
			«defRow('Supertypes', superEntities.sortBy[abbreviatedIri].map[toBikeshedReference(entity.ontology)].toUL)»
		«ENDIF»
		
		«val subEntities = entity.findSubTerms.filter(Entity).filter[t|context.contains(t)]»
		«IF !subEntities.empty»
			«defRow('Subtypes', subEntities.sortBy[abbreviatedIri].map[toBikeshedReference(entity.ontology)].toUL)»
		«ENDIF»
		
		«IF entity instanceof RelationEntity»
		
			«IF entity.forwardRelation !== null»
				«defRow('Forward relation', '''
					<dfn lt="«entity.forwardRelation.dfn»">«entity.forwardRelation.name»</dfn>
					«val relationDescription = entity.forwardRelation.getDescription(context)»
					«IF !relationDescription.empty»
						<p>«relationDescription»</p>
					«ENDIF»
				''')»
			«ENDIF»
			
			«IF entity.reverseRelation !== null»
				«defRow('Reverse relation', '''
					<dfn lt="«entity.reverseRelation.dfn»">«entity.reverseRelation.name»</dfn>
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
		
		«val propertyRestrictions = entity.findPropertyRestrictionAxioms.filter[r|context.contains(r)].toList»
		«val propertiesDirect = findSemanticPropertiesWithDomain(entity).filter[p|context.contains(p)]»
		«val propertiesWithRestrictions = propertyRestrictions.map[property] »
		«val properties = (propertiesDirect + propertiesWithRestrictions).toSet»

		«IF !properties.empty »
			«defRow('Properties', properties.sortBy[abbreviatedIri].map[getPropertyDescription(propertyRestrictions, entity.ontology)].toUL)»
		«ENDIF»

		«val keys = entity.findKeyAxioms.filter[k|context.contains(k)]»
		«IF !keys.empty»
			«defRow('Keys', keys.map[k|k.properties.sortBy[abbreviatedIri].map[toBikeshedReference(entity.ontology)].join(', ')].toUL)»
		«ENDIF»
		
		«IF entity instanceof Concept»
			«val instances = entity.findInstanceEnumerationAxioms.flatMap[instances]»
			«IF !instances.isEmpty»
				«defRow('Instances', instances.sortBy[abbreviatedIri].map[toBikeshedReference(entity.ontology)].toUL)»
			«ENDIF»
		«ENDIF»
		</table>
		
	'''
	
	// FacetedScalar
	private def dispatch String toBikeshed(Scalar scalar) '''
		«scalar.sectionHeader»
		
		«scalar.getComment(context)»
		
		«scalar.plainDescription»
		
		<table class='def'>

		«val superScalars = scalar.findSuperTerms.filter[t|context.contains(t)]»
		«IF !superScalars.empty»
			«defRow('Supertypes', superScalars.sortBy[abbreviatedIri].map[toBikeshedReference(scalar.ontology)].toUL)»
		«ENDIF»
		
		«val subScalars = scalar.findSubTerms.filter(Scalar).filter[t|context.contains(t)]»
		«IF !subScalars.empty»
			«defRow('Subtypes', subScalars.sortBy[abbreviatedIri].map[toBikeshedReference(scalar.ontology)].toUL)»
		«ENDIF»

		«val equivalenceAxioms = scalar.findScalarEquivalenceAxiomsWithSubScalar.filter[t|context.contains(t)]»
		«IF !equivalenceAxioms.empty»
			«defRow('Equivalents', equivalenceAxioms.sortBy[superScalar.abbreviatedIri].map[toBikeshed].toUL)»
		«ENDIF»

		«val literals = scalar.findLiteralEnumerationAxioms.flatMap[literals]»
		«IF !literals.empty»
			«defRow('One of', literals.sortBy[stringValue].map[stringValue].toUL)»
		«ENDIF»
		</table>
	'''

	private def dispatch String toBikeshed(ScalarEquivalenceAxiom axiom) '''
		«axiom.subScalar.toBikeshedReference(axiom.ontology)»«IF axiom.numberOfFacets > 0»(
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
		
		«property.getComment(context)»

		«property.plainDescription»
		
	'''

	private def dispatch String toBikeshed(ScalarProperty property) '''
		«property.sectionHeader»
		
		«property.getComment(context)»
		
		«property.plainDescription»
		
		<table class='def'>
			«val domains = property.domains»
			«defRow('Domains', domains.sortBy[abbreviatedIri].map[toBikeshedReference(property.ontology)].toUL)»
	
			«val ranges = property.ranges»
			«defRow('Ranges', ranges.sortBy[abbreviatedIri].map[toBikeshedReference(property.ontology)].toUL)»
			
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
		
		«property.getComment(context)»
		
		«property.plainDescription»
		
	'''
		
	private def dispatch String toBikeshed(NamedInstance instance) '''
		«instance.sectionHeader»
		
		«instance.getComment(context)»
		
		«instance.plainDescription»
		
		«val types = switch (instance) {
			ConceptInstance: instance.findTypeAssertions.map[type].filter[t|context.contains(t)].sortBy[abbreviatedIri]
			RelationInstance: instance.findTypeAssertions.map[type].filter[t|context.contains(t)].sortBy[abbreviatedIri]
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
		«val propertyValueAssertions = instance.findPropertyValueAssertionsWithSubject.filter[a|context.contains(a)].sortBy[property.abbreviatedIri]»
		«IF !propertyValueAssertions.empty»
			«defRow('Properties', propertyValueAssertions.map[toBikeshedPropertyValue(scope)].toUL)»
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
	
	private static def String toBikeshedReference(Member member, Ontology context) 
	'''<a spec="«member.ontology.iri»" lt="«member.dfn»">«member.getReferenceName(context)»</a>'''
	
	private static def String toBikeshedPropertyValue(PropertyValueAssertion assertion, Ontology scope) {
		val value = assertion.value
		val valueText = switch (value) {
			Literal: 
				value.lexicalValue
			StructureInstance: '''
				«value.type.toBikeshedReference(scope)»
				«FOR subAssertion : value.ownedPropertyValues»
					* «subAssertion.toBikeshedPropertyValue(scope)»
				«ENDFOR»
			'''
			NamedInstance: 
				value.toBikeshedReference(scope)
		}
		'''
		«assertion.property.toBikeshedReference(scope)» «valueText»'''
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
		'''## <dfn lt="«member.dfn»">«member.name»</dfn> see \[«member.name»](«desc») ## {#«member.name.toFirstUpper»}'''
		else
		'''## <dfn lt="«member.dfn»">«member.name»</dfn> ## {#«member.name.toFirstUpper»}'''
	}
	
	private static def String getReferenceName(Member member, Ontology ontology) {
		val localName = member.getAbbreviatedIriIn(ontology)
		localName ?: member.abbreviatedIri
	}
	
	private static def String getPropertyDescription(SemanticProperty property, Collection<PropertyRestrictionAxiom> restrictions, Ontology context) {
		val baseDescription = property.toBikeshedReference(context) + ' : ' + property.getRestrictedTypes(restrictions).map[toBikeshedReference(context)].toCommaSeparated
		
		val restrictionDescriptions = restrictions
			.filter[it.property == property]
			.map[axiom|
				switch (axiom) {
					PropertyRangeRestrictionAxiom: {
						val range = axiom.range
						if (axiom.kind == RangeRestrictionKind.SOME) {
							'''must include instance of «range.toBikeshedReference(context)»'''
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
						'''must have «kind» «axiom.cardinality» «axiom.range.toBikeshedReference(context)»'''
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

	private static def Iterable<Type> getRestrictedTypes(SemanticProperty property, Collection<PropertyRestrictionAxiom> restrictions) {
		val restriction = restrictions
			.filter(PropertyRangeRestrictionAxiom)
			.filter[it.property == property]
			.filter[it.kind == RangeRestrictionKind::ALL]
			.head
		
		if (restriction !== null) {
			Collections.singletonList(restriction.range)
		} else {
			OmlSearch.findRanges(property)
		}
	}

	private static def String asString(Element value) {
		if (value instanceof Literal)
			return value.lexicalValue
		else if (value instanceof StructureInstance)
			return value.type.name
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