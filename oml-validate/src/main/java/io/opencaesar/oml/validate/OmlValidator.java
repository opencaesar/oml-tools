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
package io.opencaesar.oml.validate;

import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.Diagnostician;
import org.eclipse.emf.ecore.util.EcoreUtil;

import io.opencaesar.oml.Member;
import io.opencaesar.oml.Ontology;

public class OmlValidator {

	public static void validate(Ontology ontology) {
		final Diagnostician diagnostician = new Diagnostician() {
			@Override
			public String getObjectLabel(EObject eObject) {
			    final String name;
			    if (eObject instanceof Member) {
			    	name = ((Member)eObject).getAbbreviatedIri();
			    } else if (eObject instanceof Ontology) {
			    	name = ((Ontology)eObject).getIri();
			    } else {
			    	name = EcoreUtil.getID(eObject);
			    }
			    return eObject.eClass().getName()+" "+name;
			}
		};
		
		final Diagnostic diagnostic = diagnostician.validate(ontology);
		if (diagnostic.getSeverity() == Diagnostic.ERROR) {
	        final StringBuilder sb = new StringBuilder ( diagnostic.getMessage() );
	        for (final Diagnostic child : diagnostic.getChildren()) {
	            if (child.getSeverity () == Diagnostic.ERROR) {
	                sb.append ( System.lineSeparator () );
	                sb.append ( child.getMessage () );
	            }
	        }
	        throw new IllegalStateException (sb.toString());
		}
	}

}
