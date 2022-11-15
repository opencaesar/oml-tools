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

import io.opencaesar.oml.AnnotatedElement;
import io.opencaesar.oml.AnnotationProperty;
import io.opencaesar.oml.BooleanLiteral;
import io.opencaesar.oml.Ontology;
import io.opencaesar.oml.util.OmlRead;
import io.opencaesar.oml.util.OmlSearch;

class OmlUtils {

	private static String getAnnotationStringValue(AnnotatedElement element, String abbreviatedIri, OmlSearchContext context) {
		var property = (AnnotationProperty) OmlRead.getMemberByAbbreviatedIri(element.getOntology(), abbreviatedIri);
		if (property != null) {
            final var value = OmlSearch.findAnnotationValues(element, property).stream()
            		.filter(a -> context.contains(a))
            		.findFirst().orElse(null);
			if (value != null) {
				return OmlRead.getStringValue(value);	
			}
		}
		return null;
	}

    private static boolean getAnnotationBooleanValue(AnnotatedElement element, String abbreviatedIri, OmlSearchContext context) {
		final var property = (AnnotationProperty) OmlRead.getMemberByAbbreviatedIri(element.getOntology(), abbreviatedIri);
        if (property != null) {
            final var annotation = OmlSearch.findAnnotations(element).stream()
            		.filter(a -> context.contains(a))
            		.filter(a -> a.getProperty() == property)
            		.findFirst().orElse(null);
            if (annotation == null) {
                return false;   
            }
            if (annotation.getValue() == null) {
                return true;
            }
            if (!(annotation.getValue() instanceof BooleanLiteral)) {
                return true;
            }
            return ((BooleanLiteral)annotation.getValue()).isValue();
        }
        return false;
    }

	public static String getTitle(Ontology ontology, OmlSearchContext context) {
		var value = getAnnotationStringValue(ontology, "dc:title", context);
		return (value != null) ? value : ontology.getPrefix(); 
	}

	public static String getDescription(AnnotatedElement element, OmlSearchContext context) {
		var value = getAnnotationStringValue(element, "dc:description", context);
		return (value != null) ? value : ""; 
	}
	
	public static boolean isDeprecated(AnnotatedElement element, OmlSearchContext context) {
        return getAnnotationBooleanValue(element, "owl:deprecated", context);
    }

	public static String getCreator(AnnotatedElement element, OmlSearchContext context) {
		var value = getAnnotationStringValue(element, "dc:creator", context);
		return (value != null) ? value : "Unknown"; 
	}

	public static String getCopyright(AnnotatedElement element, OmlSearchContext context) {
		var value = getAnnotationStringValue(element, "dc:rights", context);
		return ((value != null) ? value : "").replaceAll("\\R", "");
	}
	
	public static String getComment(AnnotatedElement element, OmlSearchContext context) {
		var value = getAnnotationStringValue(element, "rdfs:comment", context);
		return (value != null) ? value : ""; 
	}
	
}
