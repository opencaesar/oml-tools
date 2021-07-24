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

public class OmlUtils {

	private static String getAnnotationStringValue(AnnotatedElement element, String abbreviatedIri) {
		var property = (AnnotationProperty) OmlRead.getMemberByAbbreviatedIri(element, abbreviatedIri);
		if (property != null) {
			var value = OmlSearch.findAnnotationValue(element, property);
			if (value != null) {
				return OmlRead.getStringValue(value);	
			}
		}
		return null;
	}

    private static boolean getAnnotationBooleanValue(AnnotatedElement element, String abbreviatedIri) {
		final var property = (AnnotationProperty) OmlRead.getMemberByAbbreviatedIri(element, abbreviatedIri);
        if (property != null) {
            final var annotation = OmlSearch.findAnnotations(element).stream()
            		.filter(a -> a.getProperty() == property).findFirst().orElse(null);
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

	public static String getTitle(Ontology ontology) {
		var value = getAnnotationStringValue(ontology, "dc:title");
		return (value != null) ? value : ontology.getPrefix(); 
	}

	public static String getDescription(AnnotatedElement element) {
		var value = getAnnotationStringValue(element, "dc:description");
		return (value != null) ? value : ""; 
	}
	
	public static boolean isDeprecated(AnnotatedElement element) {
        return getAnnotationBooleanValue(element, "owl:deprecated");
    }

	public static String getCreator(AnnotatedElement element) {
		var value = getAnnotationStringValue(element, "dc:creator");
		return (value != null) ? value : "Unknown"; 
	}

	public static String getCopyright(AnnotatedElement element) {
		var value = getAnnotationStringValue(element, "dc:rights");
		return ((value != null) ? value : "").replaceAll("\\R", "");
	}
	
	public static String getComment(AnnotatedElement element) {
		var value = getAnnotationStringValue(element, "rdfs:comment");
		return (value != null) ? value : ""; 
	}
	
}
