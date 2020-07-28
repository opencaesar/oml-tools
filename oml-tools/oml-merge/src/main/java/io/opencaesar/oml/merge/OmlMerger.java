package io.opencaesar.oml.merge;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.xtext.xbase.lib.IterableExtensions;

import io.opencaesar.oml.AnnotatedElement;
import io.opencaesar.oml.Annotation;
import io.opencaesar.oml.AnnotationProperty;
import io.opencaesar.oml.Aspect;
import io.opencaesar.oml.BooleanLiteral;
import io.opencaesar.oml.CardinalityRestrictionKind;
import io.opencaesar.oml.Concept;
import io.opencaesar.oml.ConceptInstance;
import io.opencaesar.oml.ConceptTypeAssertion;
import io.opencaesar.oml.DecimalLiteral;
import io.opencaesar.oml.Description;
import io.opencaesar.oml.DescriptionBundle;
import io.opencaesar.oml.DifferentFromPredicate;
import io.opencaesar.oml.DoubleLiteral;
import io.opencaesar.oml.Element;
import io.opencaesar.oml.EntityPredicate;
import io.opencaesar.oml.EnumeratedScalar;
import io.opencaesar.oml.FacetedScalar;
import io.opencaesar.oml.ForwardRelation;
import io.opencaesar.oml.IdentifiedElement;
import io.opencaesar.oml.Import;
import io.opencaesar.oml.Instance;
import io.opencaesar.oml.IntegerLiteral;
import io.opencaesar.oml.KeyAxiom;
import io.opencaesar.oml.LinkAssertion;
import io.opencaesar.oml.Literal;
import io.opencaesar.oml.Member;
import io.opencaesar.oml.NamedInstance;
import io.opencaesar.oml.OmlPackage;
import io.opencaesar.oml.Ontology;
import io.opencaesar.oml.Predicate;
import io.opencaesar.oml.PropertyValueAssertion;
import io.opencaesar.oml.QuotedLiteral;
import io.opencaesar.oml.RangeRestrictionKind;
import io.opencaesar.oml.RelationCardinalityRestrictionAxiom;
import io.opencaesar.oml.RelationEntity;
import io.opencaesar.oml.RelationEntityPredicate;
import io.opencaesar.oml.RelationInstance;
import io.opencaesar.oml.RelationPredicate;
import io.opencaesar.oml.RelationRangeRestrictionAxiom;
import io.opencaesar.oml.RelationTargetRestrictionAxiom;
import io.opencaesar.oml.RelationTypeAssertion;
import io.opencaesar.oml.ReverseRelation;
import io.opencaesar.oml.Rule;
import io.opencaesar.oml.SameAsPredicate;
import io.opencaesar.oml.Scalar;
import io.opencaesar.oml.ScalarProperty;
import io.opencaesar.oml.ScalarPropertyCardinalityRestrictionAxiom;
import io.opencaesar.oml.ScalarPropertyRangeRestrictionAxiom;
import io.opencaesar.oml.ScalarPropertyValueAssertion;
import io.opencaesar.oml.ScalarPropertyValueRestrictionAxiom;
import io.opencaesar.oml.SpecializationAxiom;
import io.opencaesar.oml.Structure;
import io.opencaesar.oml.StructureInstance;
import io.opencaesar.oml.StructuredProperty;
import io.opencaesar.oml.StructuredPropertyCardinalityRestrictionAxiom;
import io.opencaesar.oml.StructuredPropertyRangeRestrictionAxiom;
import io.opencaesar.oml.StructuredPropertyValueAssertion;
import io.opencaesar.oml.StructuredPropertyValueRestrictionAxiom;
import io.opencaesar.oml.Vocabulary;
import io.opencaesar.oml.VocabularyBundle;
import io.opencaesar.oml.util.OmlCatalog;
import io.opencaesar.oml.util.OmlRead;
import io.opencaesar.oml.util.OmlSwitch;
import io.opencaesar.oml.util.OmlWriter;

public class OmlMerger extends OmlSwitch<Void> {

	public final static String OML = "oml";
	public final static String OMLXMI = "omlxmi";

	private OmlWriter oml;
	private OmlCatalog catalog;
	private Collection<String> errors;
	
	private Map<String, IdentifiedElement> idToElement;
	private Map<String, Element> signatureToElement;

	public OmlMerger(ResourceSet resourceSet, OmlCatalog catalog, Collection<String> errors) {
		this.oml = new OmlWriter(resourceSet);
		this.catalog = catalog;
		this.errors = errors;
		this.idToElement = new HashMap<String, IdentifiedElement>();
		this.signatureToElement = new HashMap<String, Element>();
	}

	public void start() {
		oml.start();
	}
	
	public void finish() {
		oml.finish();
	}

	public void merge(Resource inputResource) {
		for (TreeIterator<EObject> i = inputResource.getAllContents(); i.hasNext();) {
			doSwitch(i.next());
		}
	}
	
	public Collection<Resource> getMergedResources() throws IOException {
		return oml.getNewResources();
	}

	protected URI getOntologyURI(String ontologyIri) {
		String resolved;
		try {
			resolved = catalog.resolveURI(ontologyIri);
		} catch (IOException e) {
			resolved = ontologyIri;
		}
		return URI.createURI(resolved);
	}
	
	protected void reportDifferentTypes(Element input, Element output) {
		errors.add("Element "+input+" and ontology "+output+" have the same IRI but different types");
	}
	
	protected void compareElements(Element input, Element output) {
		input.eClass().getEAllAttributes().forEach(attribute -> {
			Object value1 = input.eGet(attribute);
			Object value2 = output.eGet(attribute);
			if (!Objects.equals(value1, value2)) {
				errors.add("Element "+EcoreUtil.getURI(input)+" and element "+EcoreUtil.getURI(output)+" have the same IRI but different values for attribute "+attribute.getName());
			}
		});
		input.eClass().getEAllReferences().stream().filter(it -> !it.isDerived() && !it.isContainer()).forEach(reference -> {
			if (!reference.isContainment()) {
				Object iris1 = getIris(input.eGet(reference));
				Object iris2 = getIris(output.eGet(reference));
				if (!Objects.equals(iris1, iris2)) {
					errors.add("Element "+EcoreUtil.getURI(input)+" and element "+EcoreUtil.getURI(output)+" have different values for feature "+reference.getName());
				}
			} else if (OmlPackage.Literals.LITERAL.isSuperTypeOf(reference.getEReferenceType())) {
				Object literals1 = getLiterals(input.eGet(reference));
				Object literals2 = getLiterals(output.eGet(reference));
				if (!Objects.equals(literals1, literals2)) {
					errors.add("Element "+EcoreUtil.getURI(input)+" and element "+EcoreUtil.getURI(output)+" have different values for feature "+reference.getName());
				}
			} else if (OmlPackage.Literals.PREDICATE.isSuperTypeOf(reference.getEReferenceType())) {
				Object predicates1 = getPredicates(input.eGet(reference));
				Object predicates2 = getPredicates(output.eGet(reference));
				if (!Objects.equals(predicates1, predicates2)) {
					errors.add("Element "+EcoreUtil.getURI(input)+" and element "+EcoreUtil.getURI(output)+" have different values for feature "+reference.getName());
				}
			}
		});
	}
	
	@SuppressWarnings("unchecked")
	protected Object getIris(Object value) {
		if (value instanceof List) {
			List<Member> members = (List<Member>) value;
			List<String> iris = new ArrayList<String>();
			for (Member member : members) {
				iris.add(OmlRead.getIri(member));
			}
			return iris;
		} else if (value instanceof Member) {
			Member member = (Member) value;
			return OmlRead.getIri(member);
		} else {
			return null;
		}
	}
	
	@SuppressWarnings("unchecked")
	protected Object getLiterals(Object value) {
		if (value instanceof List) {
			List<Literal> literals = (List<Literal>) value;
			List<String> strValues = new ArrayList<String>();
			for (Literal literal : literals) {
				strValues.add(toString(literal));
			}
			return strValues;
		} else if (value instanceof Literal) {
			Literal literal = (Literal) value;
			return toString(literal);
		} else {
			return null;
		}
	}
	
	@SuppressWarnings("unchecked")
	protected Object getPredicates(Object value) {
		if (value instanceof List) {
			List<Predicate> predicates = (List<Predicate>) value;
			List<String> strValues = new ArrayList<String>();
			for (Predicate predicate : predicates) {
				strValues.add(toString(predicate));
			}
			return strValues;
		} else if (value instanceof Predicate) {
			Predicate predicate = (Predicate) value;
			return toString(predicate);
		} else {
			return null;
		}
	}

	protected String toString(Literal literal) {
		Scalar type = literal.getType();
		String typeIri = (type != null) ? OmlRead.getIri(type) : "";
		switch(literal.eClass().getClassifierID()) {
			case OmlPackage.QUOTED_LITERAL: {
				QuotedLiteral l = (QuotedLiteral) literal;
				String langTag = (l.getLangTag() != null) ? l.getLangTag() : ""; 
				return "String("+l.getValue()+","+typeIri+","+langTag+")";
			}
			case OmlPackage.INTEGER_LITERAL: {
				IntegerLiteral l = (IntegerLiteral) literal;
				return "Integer("+l.getValue()+","+typeIri+")";
			}
			case OmlPackage.DECIMAL_LITERAL: {
				DecimalLiteral l = (DecimalLiteral) literal;
				return "Decimal("+l.getValue()+","+typeIri+")";
			}
			case OmlPackage.DOUBLE_LITERAL: {
				DoubleLiteral l = (DoubleLiteral) literal;
				return "Double("+l.getValue()+","+typeIri+")";
			}
			case OmlPackage.BOOLEAN_LITERAL: {
				BooleanLiteral l = (BooleanLiteral) literal;
				return "Boolean("+l.isValue()+","+typeIri+")";
			}
		}
		return null;
	}

	protected String toString(Predicate predicate) {
		switch(predicate.eClass().getClassifierID()) {
			case OmlPackage.ENTITY_PREDICATE: {
				EntityPredicate p = (EntityPredicate) predicate;
				String entityIri = OmlRead.getIri(p.getEntity());
				return entityIri+"("+p.getVariable()+")";
			}
			case OmlPackage.RELATION_PREDICATE: {
				RelationPredicate p = (RelationPredicate) predicate;
				String relationIri = OmlRead.getIri(p.getRelation());
				return relationIri+"("+p.getVariable1()+","+p.getVariable2()+")";
			}
			case OmlPackage.RELATION_ENTITY_PREDICATE: {
				RelationEntityPredicate p = (RelationEntityPredicate) predicate;
				String entityIri = OmlRead.getIri(p.getEntity());
				return entityIri+"("+p.getVariable1()+","+p.getEntityVariable()+","+p.getVariable2()+")";
			}
			case OmlPackage.SAME_AS_PREDICATE: {
				SameAsPredicate p = (SameAsPredicate) predicate;
				return "SameAs("+p.getVariable1()+","+p.getVariable2()+")";
			}
			case OmlPackage.DIFFERENT_FROM_PREDICATE: {
				DifferentFromPredicate p = (DifferentFromPredicate) predicate;
				return "DifferentFrom("+p.getVariable1()+","+p.getVariable2()+")";
			}
		}
		return null;
	}
	
	protected String toString(StructureInstance instance) {
		String value = OmlRead.getIri(instance.getType());
		value += "{";
		for (PropertyValueAssertion assertion : instance.getOwnedPropertyValues()) {
			if (assertion instanceof ScalarPropertyValueAssertion) {
				ScalarPropertyValueAssertion a = (ScalarPropertyValueAssertion) assertion;
				value += OmlRead.getIri(a.getProperty());
				value +="=";
				value += copy(a.getValue());
			} else if (assertion instanceof StructuredPropertyValueAssertion) {
				StructuredPropertyValueAssertion a = (StructuredPropertyValueAssertion) assertion;
				value += OmlRead.getIri(a.getProperty());
				value +="=";
				value += copy(a.getValue());
			}
		}
		value += "}";
		return value;
	}
	
	//----------------------------------------------------------------------------------------------------

	@Override
	public Void caseOntology(Ontology input) {
		IdentifiedElement output = idToElement.get(input.getIri());
		if (output == null) {
			switch(input.eClass().getClassifierID()) {
				case OmlPackage.VOCABULARY: 
					output = oml.createVocabulary(getOntologyURI(input.getIri()+'.'+OML), input.getIri(), input.getSeparator(), input.getPrefix());
					break;
				case OmlPackage.VOCABULARY_BUNDLE: 
					output = oml.createVocabularyBundle(getOntologyURI(input.getIri()+'.'+OML), input.getIri(), input.getSeparator(), input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION: 
					output = oml.createDescription(getOntologyURI(input.getIri()+'.'+OMLXMI), input.getIri(), input.getSeparator(), input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION_BUNDLE: 
					output = oml.createDescriptionBundle(getOntologyURI(input.getIri()+'.'+OMLXMI), input.getIri(), input.getSeparator(), input.getPrefix());
					break;
			}
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseImport(Import input) {
		String importingIri = OmlRead.getImportingOntology(input).getIri();
		String importedIri = OmlRead.getImportedOntology(input).getIri();
		
		Ontology ontology = (Ontology) idToElement.get(importingIri);
		Iterable<Import> imports = OmlRead.getImportsWithSource(ontology);
		Import output = IterableExtensions.findFirst(imports, it -> it.getUri().equals(importedIri));
				
		if (output == null) {
			switch(input.eClass().getClassifierID()) {
				case OmlPackage.VOCABULARY_EXTENSION: 
					output = oml.addVocabularyExtension((Vocabulary)ontology, importedIri, input.getPrefix());
					break;
				case OmlPackage.VOCABULARY_USAGE: 
					output = oml.addVocabularyUsage((Vocabulary)ontology, importedIri+'.'+OMLXMI, input.getPrefix());
					break;
				case OmlPackage.VOCABULARY_BUNDLE_EXTENSION: 
					output = oml.addVocabularyBundleExtension((VocabularyBundle)ontology, importedIri, input.getPrefix());
					break;
				case OmlPackage.VOCABULARY_BUNDLE_INCLUSION: 
					output = oml.addVocabularyBundleInclusion((VocabularyBundle)ontology, importedIri, input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION_EXTENSION: 
					output = oml.addDescriptionExtension((Description)ontology, importedIri+'.'+OMLXMI, input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION_USAGE: 
					output = oml.addDescriptionUsage((Description)ontology, importedIri, input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION_BUNDLE_EXTENSION: 
					output = oml.addDescriptionBundleExtension((DescriptionBundle)ontology, importedIri+'.'+OMLXMI, input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION_BUNDLE_INCLUSION: 
					output = oml.addDescriptionBundleInclusion((DescriptionBundle)ontology, importedIri+'.'+OMLXMI, input.getPrefix());
					break;
				case OmlPackage.DESCRIPTION_BUNDLE_USAGE: 
					output = oml.addDescriptionBundleUsage((DescriptionBundle)ontology, importedIri, input.getPrefix());
					break;
			}
		} else if (input.eClass() != output.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}	
		
		AnnotatedElement finalOutput = output;
		String signature = "Import("+importingIri+","+importedIri+")";
		input.getOwnedAnnotations().forEach(it -> {
			copyAnnotation(finalOutput, signature, it);	
		});
		
		return null;
	}

	//----------------------------------------------------------------------------------------------------

	@Override
	public Void caseAspect(Aspect input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			output = oml.addAspect(vocabulary, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseConcept(Concept input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			output = oml.addConcept(vocabulary, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseRelationEntity(RelationEntity input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			String sourceIri = OmlRead.getIri(input.getSource());
			String targetIri = OmlRead.getIri(input.getTarget());
			output = oml.addRelationEntity(vocabulary, input.getName(), sourceIri, targetIri, 
				input.isFunctional(), input.isInverseFunctional(), input.isSymmetric(), input.isAsymmetric(),
				input.isReflexive(), input.isIrreflexive(), input.isTransitive());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseForwardRelation(ForwardRelation input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			RelationEntity entity = (RelationEntity) idToElement.get(OmlRead.getIri(input.getEntity()));
			output = oml.addForwardRelation(entity, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseReverseRelation(ReverseRelation input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			RelationEntity entity = (RelationEntity) idToElement.get(OmlRead.getIri(input.getEntity()));
			output = oml.addReverseRelation(entity, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseStructure(Structure input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			output = oml.addStructure(vocabulary, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseFacetedScalar(FacetedScalar input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			output = oml.addFacetedScalar(vocabulary, input.getName(), input.getLength(), 
				input.getMinLength(), input.getMaxLength(), input.getPattern(), input.getLanguage(),
				copy(input.getMinInclusive()), copy(input.getMinExclusive()), 
				copy(input.getMaxInclusive()), copy(input.getMaxExclusive()));
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseEnumeratedScalar(EnumeratedScalar input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			List<Literal> literals = new ArrayList<Literal>();
			for (Literal literal : input.getLiterals()) {
				literals.add(copy(literal));
			}
			output = oml.addEnumeratedScalar(vocabulary, input.getName(), literals.toArray(new Literal[0]));
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseAnnotationProperty(AnnotationProperty input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			output = oml.addAnnotationProperty(vocabulary, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseScalarProperty(ScalarProperty input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			String domainIri = OmlRead.getIri(input.getDomain());
			String rangeIri = OmlRead.getIri(input.getRange());
			output = oml.addScalarProperty(vocabulary, input.getName(), domainIri, rangeIri, input.isFunctional());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseStructuredProperty(StructuredProperty input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			String domainIri = OmlRead.getIri(input.getDomain());
			String rangeIri = OmlRead.getIri(input.getRange());
			output = oml.addStructuredProperty(vocabulary, input.getName(), domainIri, rangeIri, input.isFunctional());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseRule(Rule input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getVocabulary(input).getIri());
			List<Predicate> consequent = new ArrayList<Predicate>();
			for (Predicate predicate : input.getConsequent()) {
				consequent.add(copy(predicate));
			}
			List<Predicate> antecedent = new ArrayList<Predicate>();
			for (Predicate predicate : input.getAntecedent()) {
				antecedent.add(copy(predicate));
			}
			output = oml.addRule(vocabulary, input.getName(), consequent.toArray(new Predicate[0]), antecedent.toArray(new Predicate[0]));
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseConceptInstance(ConceptInstance input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Description description = (Description) idToElement.get(OmlRead.getDescription(input).getIri());
			output = oml.addConceptInstance(description, input.getName());
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	@Override
	public Void caseRelationInstance(RelationInstance input) {
		IdentifiedElement output = idToElement.get(OmlRead.getIri(input));
		if (output == null) {
			Description description = (Description) idToElement.get(OmlRead.getDescription(input).getIri());
			String sourceIri = OmlRead.getIri(input.getSource());
			String targetIri = OmlRead.getIri(input.getTarget());
			output = oml.addRelationInstance(description, input.getName(), sourceIri, targetIri);
			idToElement.put(OmlRead.getIri(output), output);
		} else if (output.eClass() != input.eClass()) {
			reportDifferentTypes(input, output);
		} else {
			compareElements(input, output);
		}
		return null;
	}

	//---------------------------------------------------------------------
	
	@Override
	public Void caseSpecializationAxiom(SpecializationAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String specializingIri = OmlRead.getIri(OmlRead.getSpecializingTerm(input));
		String specializedIri = OmlRead.getIri(input.getSpecializedTerm());
		
		String signature = "SpecializationAxiom("+vocabulary.getIri()+","+specializingIri+","+specializedIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addSpecializationAxiom(vocabulary, specializingIri, specializedIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseScalarPropertyRangeRestrictionAxiom(ScalarPropertyRangeRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String propertyIri = OmlRead.getIri(input.getProperty());
		String rangeIri = OmlRead.getIri(input.getRange());
		RangeRestrictionKind kind = input.getKind();
		
		String signature = "ScalarPropertyRangeRestrictionAxiom("+vocabulary.getIri()+","+typeIri+","+propertyIri+","+rangeIri+","+kind+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addScalarPropertyRangeRestrictionAxiom(vocabulary, typeIri, propertyIri, rangeIri, kind);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseScalarPropertyCardinalityRestrictionAxiom(ScalarPropertyCardinalityRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String propertyIri = OmlRead.getIri(input.getProperty());
		CardinalityRestrictionKind kind = input.getKind();
		long cardinality = input.getCardinality();
		String rangeIri = OmlRead.getIri(input.getRange());
		
		String signature = "ScalarPropertyCardinalityRestrictionAxiom("+vocabulary.getIri()+","+typeIri+","+propertyIri+","+kind+","+cardinality+","+rangeIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addScalarPropertyCardinalityRestrictionAxiom(vocabulary, typeIri, propertyIri, kind, cardinality, rangeIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseScalarPropertyValueRestrictionAxiom(ScalarPropertyValueRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String propertyIri = OmlRead.getIri(input.getProperty());
		Literal value = copy(input.getValue());
		
		String signature = "ScalarPropertyValueRestrictionAxiom("+vocabulary.getIri()+","+typeIri+","+propertyIri+","+toString(value)+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addScalarPropertyValueRestrictionAxiom(vocabulary, typeIri, propertyIri, value);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseStructuredPropertyRangeRestrictionAxiom(StructuredPropertyRangeRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String propertyIri = OmlRead.getIri(input.getProperty());
		String rangeIri = OmlRead.getIri(input.getRange());
		RangeRestrictionKind kind = input.getKind();
		
		String signature = "StructuredPropertyRangeRestrictionAxiom("+vocabulary.getIri()+","+typeIri+","+propertyIri+","+rangeIri+","+kind+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addStructuredPropertyRangeRestrictionAxiom(vocabulary, typeIri, propertyIri, rangeIri, kind);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseStructuredPropertyCardinalityRestrictionAxiom(StructuredPropertyCardinalityRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String propertyIri = OmlRead.getIri(input.getProperty());
		CardinalityRestrictionKind kind = input.getKind();
		long cardinality = input.getCardinality();
		String rangeIri = OmlRead.getIri(input.getRange());
		
		String signature = "StructuredPropertyCardinalityRestrictionAxiom("+vocabulary.getIri()+","+typeIri+","+propertyIri+","+kind+","+cardinality+","+rangeIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addStructuredPropertyCardinalityRestrictionAxiom(vocabulary, typeIri, propertyIri, kind, cardinality, rangeIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseStructuredPropertyValueRestrictionAxiom(StructuredPropertyValueRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String propertyIri = OmlRead.getIri(input.getProperty());
		StructureInstance value = copy(input.getValue());
		
		String signature = "StructuredPropertyValueRestrictionAxiom("+vocabulary.getIri()+","+typeIri+","+propertyIri+","+toString(value)+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addStructuredPropertyValueRestrictionAxiom(vocabulary, typeIri, propertyIri, value);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseRelationRangeRestrictionAxiom(RelationRangeRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String entityIri = OmlRead.getIri(OmlRead.getRestrictingEntity(input));
		String relationIri = OmlRead.getIri(input.getRelation());
		String rangeIri = OmlRead.getIri(input.getRange());
		RangeRestrictionKind kind = input.getKind();
		
		String signature = "RelationRangeRestrictionAxiom("+vocabulary.getIri()+","+entityIri+","+relationIri+","+rangeIri+","+kind+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addRelationRangeRestrictionAxiom(vocabulary, entityIri, relationIri, rangeIri, kind);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseRelationCardinalityRestrictionAxiom(RelationCardinalityRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String entityIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String relationIri = OmlRead.getIri(input.getRelation());
		CardinalityRestrictionKind kind = input.getKind();
		long cardinality = input.getCardinality();
		String rangeIri = OmlRead.getIri(input.getRange());
		
		String signature = "RelationCardinalityRestrictionAxiom("+vocabulary.getIri()+","+entityIri+","+relationIri+","+kind+","+cardinality+","+rangeIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addRelationCardinalityRestrictionAxiom(vocabulary, entityIri, relationIri, kind, cardinality, rangeIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseRelationTargetRestrictionAxiom(RelationTargetRestrictionAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String entityIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		String relationIri = OmlRead.getIri(input.getRelation());
		String targetIri = OmlRead.getIri(input.getTarget());
		
		String signature = "RelationTargetRestrictionAxiom("+vocabulary.getIri()+","+entityIri+","+relationIri+","+targetIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addRelationTargetRestrictionAxiom(vocabulary, entityIri, relationIri, targetIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseKeyAxiom(KeyAxiom input) {
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		String entityIri = OmlRead.getIri(OmlRead.getRestrictingType(input));
		List<String> keyPropertyIris = new ArrayList<String>();
		for (ScalarProperty p : input.getProperties()) {
			keyPropertyIris.add(OmlRead.getIri(p));
		}
		
		String signature = "KeyAxiom("+vocabulary.getIri()+","+entityIri+","+keyPropertyIris+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addKeyAxiom(vocabulary, entityIri, keyPropertyIris);
			signatureToElement.put(signature, output);
		}

		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseConceptTypeAssertion(ConceptTypeAssertion input) {
		Description description = (Description) idToElement.get(OmlRead.getOntology(input).getIri());
		String instanceIri = OmlRead.getIri(OmlRead.getConceptInstance(input));
		String typeIri = OmlRead.getIri(input.getType());
		
		String signature = "ConceptTypeAssertion("+description.getIri()+","+instanceIri+","+typeIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addConceptTypeAssertion(description, instanceIri, typeIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseRelationTypeAssertion(RelationTypeAssertion input) {
		Description description = (Description) idToElement.get(OmlRead.getOntology(input).getIri());
		String instanceIri = OmlRead.getIri(OmlRead.getRelationInstance(input));
		String typeIri = OmlRead.getIri(input.getType());
		
		String signature = "RelationTypeAssertion("+description.getIri()+","+instanceIri+","+typeIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addRelationTypeAssertion(description, instanceIri, typeIri);
			signatureToElement.put(signature, output);
		}
		
		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	@Override
	public Void caseScalarPropertyValueAssertion(ScalarPropertyValueAssertion input) {
		Instance instance = OmlRead.getInstance(input);
		if (instance instanceof NamedInstance) {
			Description description = (Description) idToElement.get(OmlRead.getOntology(input).getIri());
			String instanceIri = OmlRead.getIri((NamedInstance) instance);
			String propertyIri = OmlRead.getIri(input.getProperty());
			Literal value = copy(input.getValue());
			
			String signature = "ScalarPropertyValueAssertion("+description.getIri()+","+instanceIri+","+propertyIri+","+toString(value)+")";
	
			AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
			if (output == null) {
				output = oml.addScalarPropertyValueAssertion(description, instanceIri, propertyIri, value);
				signatureToElement.put(signature, output);
			}

			AnnotatedElement finalOutput = output;
			input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		}
		return null;
	}

	@Override
	public Void caseStructuredPropertyValueAssertion(StructuredPropertyValueAssertion input) {
		Instance instance = OmlRead.getInstance(input);
		if (instance instanceof NamedInstance) {
			Description description = (Description) idToElement.get(OmlRead.getOntology(input).getIri());
			String instanceIri = OmlRead.getIri((NamedInstance) instance);
			String propertyIri = OmlRead.getIri(input.getProperty());
			StructureInstance value = copy(input.getValue());
			
			String signature = "StructuredPropertyValueAssertion("+description.getIri()+","+instanceIri+","+propertyIri+","+toString(value)+")";
	
			AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
			if (output == null) {
				output = oml.addStructuredPropertyValueAssertion(description, instanceIri, propertyIri, value);
				signatureToElement.put(signature, output);
			}

			AnnotatedElement finalOutput = output;
			input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		}
		return null;
	}

	@Override
	public Void caseLinkAssertion(LinkAssertion input) {
		Description description = (Description) idToElement.get(OmlRead.getOntology(input).getIri());
		String instanceIri = OmlRead.getIri(OmlRead.getNamedInstance(input));
		String relationIri = OmlRead.getIri(input.getRelation());
		String targetIri = OmlRead.getIri(input.getTarget());
		
		String signature = "LinkAssertion("+description.getIri()+","+instanceIri+","+relationIri+","+targetIri+")";

		AnnotatedElement output = (AnnotatedElement) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addLinkAssertion(description, instanceIri, relationIri, targetIri);
			signatureToElement.put(signature, output);
		}

		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, signature, it));
		return null;
	}

	//--------------------------------------------------------------

	@Override
	public Void caseAnnotation(Annotation input) {
		Ontology ontology = (Ontology) idToElement.get(OmlRead.getOntology(input).getIri());
		Element element = OmlRead.getAnnotatedElement(input);
		
		if (element instanceof Ontology) {
			copyAnnotation(ontology, ontology.getIri(), input);
		} else if (element instanceof Member) {
			copyAnnotation(ontology, (Member)element, input);
		}
		return null;
	}

	//--------------------------------------------------------------
	
	protected Literal copy(Literal input) {
		if (input == null) {
			return null;
		}
		Ontology ontology = (Ontology) idToElement.get(OmlRead.getOntology(input).getIri());
		String typeIri = (input.getType() != null)? OmlRead.getIri(input.getType()) : null;
		Literal output = null;
		switch(input.eClass().getClassifierID()) {
			case OmlPackage.QUOTED_LITERAL: {
				output = oml.createQuotedLiteral(ontology, ((QuotedLiteral)input).getValue(), typeIri, ((QuotedLiteral)input).getLangTag());
				break;
			}
			case OmlPackage.INTEGER_LITERAL: {
				output = oml.createIntegerLiteral(ontology, ((IntegerLiteral)input).getValue(), typeIri);
				break;
			}
			case OmlPackage.DECIMAL_LITERAL: {
				output = oml.createDecimalLiteral(ontology, ((DecimalLiteral)input).getValue(), typeIri);
				break;
			}
			case OmlPackage.DOUBLE_LITERAL: {
				output = oml.createDoubleLiteral(ontology, ((DoubleLiteral)input).getValue(), typeIri);
				break;
			}
			case OmlPackage.BOOLEAN_LITERAL: {
				output = oml.createBooleanLiteral(ontology, ((BooleanLiteral)input).isValue(), typeIri);
				break;
			}
		}
		return output;
	}

	protected Predicate copy(Predicate input) {
		if (input == null) {
			return null;
		}
		Vocabulary vocabulary = (Vocabulary) idToElement.get(OmlRead.getOntology(input).getIri());
		Predicate output = null;
		switch(input.eClass().getClassifierID()) {
			case OmlPackage.ENTITY_PREDICATE: {
				EntityPredicate predicate = (EntityPredicate) input;
				String entityIri = OmlRead.getIri(predicate.getEntity());
				output = oml.createEntityPredicate(vocabulary, entityIri, predicate.getVariable());
				break;
			}
			case OmlPackage.RELATION_PREDICATE: {
				RelationPredicate predicate = (RelationPredicate) input;
				String relationIri = OmlRead.getIri(predicate.getRelation());
				output = oml.createRelationPredicate(vocabulary, relationIri, predicate.getVariable1(), predicate.getVariable2());
				break;
			}
			case OmlPackage.RELATION_ENTITY_PREDICATE: {
				RelationEntityPredicate predicate = (RelationEntityPredicate) input;
				String entityIri = OmlRead.getIri(predicate.getEntity());
				output = oml.createRelationEntityPredicate(vocabulary, entityIri, predicate.getVariable1(), predicate.getEntityVariable(), predicate.getVariable2());
				break;
			}
			case OmlPackage.SAME_AS_PREDICATE: {
				SameAsPredicate predicate = (SameAsPredicate) input;
				output = oml.createSameAsPredicate(vocabulary, predicate.getVariable1(), predicate.getVariable2());
				break;
			}
			case OmlPackage.DIFFERENT_FROM_PREDICATE: {
				DifferentFromPredicate predicate = (DifferentFromPredicate) input;
				output = oml.createDifferentFromPredicate(vocabulary, predicate.getVariable1(), predicate.getVariable2());
				break;
			}
		}

		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, it));

		return output;
	}
	
	protected StructureInstance copy(StructureInstance input) {
		Ontology ontology = (Ontology) idToElement.get(OmlRead.getOntology(input).getIri());
		String structureIri = OmlRead.getIri(input.getType());
		StructureInstance output = oml.createStructureInstance(ontology, structureIri);
		
		for (PropertyValueAssertion assertion : input.getOwnedPropertyValues()) {
			PropertyValueAssertion outputAssertion = null;
			if (assertion instanceof ScalarPropertyValueAssertion) {
				ScalarPropertyValueAssertion a = (ScalarPropertyValueAssertion) assertion;
				String propertyIri = OmlRead.getIri(a.getProperty());
				Literal value = copy(a.getValue());
				outputAssertion = oml.addScalarPropertyValueAssertion(output, propertyIri, value);
			} else if (assertion instanceof StructuredPropertyValueAssertion) {
				StructuredPropertyValueAssertion a = (StructuredPropertyValueAssertion) assertion;
				String propertyIri = OmlRead.getIri(a.getProperty());
				StructureInstance value = copy(a.getValue());
				outputAssertion = oml.addStructuredPropertyValueAssertion(output, propertyIri, value);
			}
			AnnotatedElement finalOutput = outputAssertion;
			input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, it));
		}

		AnnotatedElement finalOutput = output;
		input.getOwnedAnnotations().forEach(it -> copyAnnotation(finalOutput, it));
		
		return output;
	}
	
	protected Annotation copyAnnotation(AnnotatedElement element, Annotation input) {
		String propertyIri = OmlRead.getIri(input.getProperty());
		Literal value = copy(input.getValue());
		return oml.addAnnotation(element, propertyIri, value);
	}
	
	protected Annotation copyAnnotation(AnnotatedElement element, String elementSignature, Annotation input) {
		String propertyIri = OmlRead.getIri(input.getProperty());
		Literal value = copy(input.getValue());
		
		String signature = "Annotation("+elementSignature+","+propertyIri+","+toString(value)+")";
		
		Annotation output = (Annotation) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addAnnotation(element, propertyIri, value);
			signatureToElement.put(signature, output);
		}
		return output;
	}

	protected Annotation copyAnnotation(Ontology ontology, Member member, Annotation input) {
		String propertyIri = OmlRead.getIri(input.getProperty());
		Literal value = copy(input.getValue());
		
		String signature = "Annotation("+ontology.getIri()+","+OmlRead.getIri(member)+","+propertyIri+","+toString(value)+")";
		
		Annotation output = (Annotation) signatureToElement.get(signature);
		if (output == null) {
			output = oml.addAnnotation(ontology, OmlRead.getIri(member), propertyIri, value);
			signatureToElement.put(signature, output);
		}
		return output;
	}

}
