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
package io.opencaesar.oml.bikeshed;

import java.util.Set;

import org.eclipse.emf.ecore.resource.Resource;

import io.opencaesar.oml.AnnotationProperty;
import io.opencaesar.oml.BooleanLiteral;
import io.opencaesar.oml.IdentifiedElement;
import io.opencaesar.oml.Literal;
import io.opencaesar.oml.Member;
import io.opencaesar.oml.Ontology;
import io.opencaesar.oml.util.OmlRead;
import io.opencaesar.oml.util.OmlSearch;

class OmlUtils {

	private static String findAnnotationStringValue(IdentifiedElement element, String abbreviatedIri, Set<Resource> scope) {
		var property = (AnnotationProperty) OmlRead.getMemberByAbbreviatedIri(element.getOntology(), abbreviatedIri);
		if (property != null) {
	        final var values = OmlSearch.findAnnotationValues(element, property, scope);
	        if (!values.isEmpty()) {
	        	var value = values.iterator().next();
		        if (value instanceof Literal) {
					return ((Literal)value).getStringValue();
				} else if (value instanceof Member) {
					return ((Member)value).getAbbreviatedIri();
				}
	        }
		}
		return null;
	}

    private static boolean findAnnotationBooleanValue(IdentifiedElement element, String abbreviatedIri, Set<Resource> scope) {
		final var property = (AnnotationProperty) OmlRead.getMemberByAbbreviatedIri(element.getOntology(), abbreviatedIri);
        if (property != null) {
            final var value = OmlSearch.findAnnotationLiteralValue(element, property, scope);
            if (!(value instanceof BooleanLiteral)) {
                return true;
            }
            return ((BooleanLiteral)value).isValue();
        }
        return false;
    }

	public static String findTitle(Ontology ontology, Set<Resource> scope) {
		var value = findAnnotationStringValue(ontology, "dc:title", scope);
		return (value != null) ? value : ontology.getPrefix(); 
	}

	public static String findDescription(IdentifiedElement element, Set<Resource> scope) {
		var value = findAnnotationStringValue(element, "dc:description", scope);
		return (value != null) ? value : ""; 
	}
	
	public static boolean findIsDeprecated(IdentifiedElement element, Set<Resource> scope) {
        return findAnnotationBooleanValue(element, "owl:deprecated", scope);
    }

	public static String findCreator(IdentifiedElement element, Set<Resource> scope) {
		var value = findAnnotationStringValue(element, "dc:creator", scope);
		return (value != null) ? value : "Unknown"; 
	}

	public static String findCopyright(IdentifiedElement element, Set<Resource> scope) {
		var value = findAnnotationStringValue(element, "dc:rights", scope);
		return ((value != null) ? value : "").replaceAll("\\R", "");
	}
	
	public static String findComment(IdentifiedElement element, Set<Resource> scope) {
		var value = findAnnotationStringValue(element, "rdfs:comment", scope);
		return (value != null) ? value : ""; 
	}
	
}
