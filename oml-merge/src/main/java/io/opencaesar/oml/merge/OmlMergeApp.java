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
package io.opencaesar.oml.merge;

import java.io.BufferedInputStream;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import org.apache.log4j.Appender;
import org.apache.log4j.AppenderSkeleton;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;

import io.opencaesar.oml.util.OmlConstants;

/**
 * An app to unzip and merge a set of archived files into a folder
 */
public class OmlMergeApp {

    @Parameter(
            names = {"--input-zip-path", "-z"},
            description = "Paths to input OML zip archives (Not required)",
            validateWith = InputZipPath.class,
            order = 1)
    private List<String> inputZipPaths = new ArrayList<>();

    @Parameter(
            names = {"--input-folder-path", "-f"},
            description = "Paths to input OML folders (Not required)",
            validateWith = InputFolderPath.class,
            order = 2)
    private List<String> inputFolderPaths = new ArrayList<>();

    @Parameter(
            names = {"--input-catalog-path", "-c"},
            description = "Paths to input OML catalog files (Not Required)",
            validateWith = InputCatalogPath.class,
            order = 3)
    private List<String> inputCatalogPaths = new ArrayList<>();

    @Parameter(
            names = {"--output-folder-path", "-o"},
            description = "Path to output OML folder where a basic OML catalog will be created (Required)",
            validateWith = OutputFilePath.class,
            required = true,
            order = 4)
    private String outputFolderPath = null;

    @Parameter(
            names = {"--generate-output-catalog", "-g"},
            description = "Whether to generate a catalog file in the output folder path (Not Required)",
            order = 5)
    private boolean generateOutputCatalog;

    @Parameter(
            names = {"--debug", "-d"},
            description = "Whether to show debug logging statements",
            order = 6)
    private boolean debug;

    @Parameter(
            names = {"--help", "-h"},
            description = "Whether to displaya a summary of options",
            help = true,
            order = 7)
    private boolean help;

    private final Logger LOGGER = Logger.getLogger(OmlMergeApp.class);

	/**
	 * Main method
	 * 
	 * @param args command line arguments for the app
	 * @throws Exception when template instantiation has a problem
	 */
    public static void main(final String... args) throws Exception {
        final OmlMergeApp app = new OmlMergeApp();
        final JCommander builder = JCommander.newBuilder().addObject(app).build();
        builder.parse(args);
        if (app.help) {
            builder.usage();
            return;
        }
        DOMConfigurator.configure(ClassLoader.getSystemClassLoader().getResource("log4j.xml"));
        if (app.debug) {
            final Appender appender = Logger.getRootLogger().getAppender("stdout");
            ((AppenderSkeleton) appender).setThreshold(Level.DEBUG);
        }
        Collection<UniqueFile> differences = app.run();
        if (!differences.isEmpty())
            System.exit(255);
    }

    /**
     * Creates a new OmlMergeApp object
     */
    public OmlMergeApp() {
    }

	/**
	 * Run method
	 * 
	 * @return List of UniqueFiles
	 * @throws IOException error
	 */
    public List<UniqueFile> run() throws IOException {
        LOGGER.info("=================================================================");
        LOGGER.info("                        S T A R T");
        LOGGER.info("                       OML Merge " + getAppVersion());
        LOGGER.info("=================================================================");
        if (inputZipPaths.isEmpty() && inputFolderPaths.isEmpty() && inputCatalogPaths.isEmpty())
            throw new IllegalArgumentException("No inputs specified!");

        LOGGER.info(("Input Zips = [" + String.join(", ", inputZipPaths)) + "]");
        LOGGER.info(("Input Folders = [" + String.join(", ", inputFolderPaths)) + "]");
        LOGGER.info(("Input Catalogs = [" + String.join(", ", inputCatalogPaths)) + "]");
        LOGGER.info("Output Folder = " + outputFolderPath);

        // Create output OML Catalog
        LOGGER.info("Saving: " + outputFolderPath);
        File outputFolder = new File(outputFolderPath);
        outputFolder.mkdirs();

        if (generateOutputCatalog) {
	        File outputCatalogFile = outputFolder.toPath().resolve("catalog.xml").toFile();
	        BufferedWriter bw = new BufferedWriter(new FileWriter(outputCatalogFile));
	        bw.write(
	                "<?xml version='1.0'?>\n" +
	                        "<catalog xmlns=\"urn:oasis:names:tc:entity:xmlns:xml:catalog\" prefer=\"public\">\n" +
	                        "\t<rewriteURI uriStartString=\"http://\" rewritePrefix=\"./\" />\n" +
	                        "</catalog>"
	        );
	        bw.close();
        }

        List<InputFiles> allInputs = new ArrayList<>();

        byte[] buffer = new byte[4096];
        for (String inputZipPath : inputZipPaths) {
            Path dir = Files.createTempDirectory("oml-");
            dir.toFile().deleteOnExit();
            ZipInputStream zis = new ZipInputStream(new FileInputStream(inputZipPath));
            ZipEntry ze;
            while (null != (ze = zis.getNextEntry())) {
                File f = dir.resolve(ze.getName()).toFile();
                f.deleteOnExit();
                if (ze.isDirectory())
                    f.mkdirs();
                else {
                    FileOutputStream fos = new FileOutputStream(f);
                    int len;
                    while ((len = zis.read(buffer)) > 0) {
                        fos.write(buffer, 0, len);
                    }
                    fos.close();
                }
                zis.closeEntry();
            }
            zis.close();
            Collection<UniqueFile> ufs = collectOMLUniqueFiles(dir.toFile());
            allInputs.add(new InputFiles(inputZipPath, ufs));
        }

        for (String inputFolderPath : inputFolderPaths) {
            File dir = new File(inputFolderPath);
            Collection<UniqueFile> ufs = collectOMLUniqueFiles(dir);
            allInputs.add(new InputFiles(inputFolderPath, ufs));
        }

        for (String inputCatalogPath : inputCatalogPaths) {
            File inputCatalogFile = new File(inputCatalogPath);
            File inputFolder = inputCatalogFile.getParentFile();
            Collection<UniqueFile> ufs = collectOMLUniqueFiles(inputFolder);
            allInputs.add(new InputFiles(inputCatalogPath, ufs));
        }

        Map<Path, UniqueFile> uniqueFiles = new HashMap<>();

        allInputs.forEach((InputFiles inputFiles) -> {
            inputFiles.files.forEach((UniqueFile f) -> {
                if (!uniqueFiles.containsKey(f.relativePath)) {
                    f.inputs.add(inputFiles.input);
                    uniqueFiles.put(f.relativePath, f);
                } else {
                    UniqueFile uf = uniqueFiles.get(f.relativePath);
                    if (uf.extension.equals(f.extension) && Arrays.equals(uf.hash, f.hash))
                        uf.inputs.add(inputFiles.input);
                    else {
                        uf.differentInputs.add(inputFiles.input);
                    }
                }
            });
        });

        List<UniqueFile> differences = uniqueFiles.values().stream().filter(uf -> !uf.differentInputs.isEmpty()).collect(Collectors.toList());

        // Check errors
        if (!differences.isEmpty()) {
            LOGGER.error(differences.size() + " differences found.");
            for (UniqueFile difference : differences) {
                LOGGER.error(difference.toError());
            }
        }

        for (UniqueFile uf : uniqueFiles.values()) {
            String relativeFile = uf.relativePath.toString() + "." + uf.extension;
            Path outputFile = outputFolder.toPath().resolve(relativeFile);
            outputFile.getParent().toFile().mkdirs();
            Path inputFile = uf.top.resolve(relativeFile);
            Files.copy(inputFile, outputFile, StandardCopyOption.REPLACE_EXISTING);
        }

        LOGGER.info("=================================================================");
        LOGGER.info("                          E N D");
        LOGGER.info("=================================================================");

        return differences;
    }
    
    /**
     * Returns the SHA-256 hash of the contents of the given InputStream with CR and CRLF
     * line endings normalized to LF.
     * 
     * @param is an input stream to return the hash of
     * @return byte[] representing the SHA-256 hash of the input stream's contents
     * @throws java.io.IOException if there is an errpr reading the input stream
     */
    public static byte[] normalizedHash(InputStream is) throws IOException {
        try (BufferedInputStream bis = new BufferedInputStream(is)) {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            int b;
            while ((b = bis.read()) != -1) {
                if (b == '\r') {
                    // Replace CR with LF
                    b = '\n';
                    // Ignore LF immediately after CR
                    bis.mark(1);
                    if (bis.read() != '\n') {
                        bis.reset();
                    }
                }
                digest.update((byte) b);
            }
            return digest.digest();
        } catch (NoSuchAlgorithmException e) {
            throw new AssertionError(e);
        }
    }

    private static Collection<UniqueFile> collectOMLUniqueFiles(File directory) throws IOException {
        Path top = directory.toPath();
        Collection<UniqueFile> ufiles = new ArrayList<>();
        for (PathAndExtension pe : collectOMLFiles(directory)) {
            ufiles.add(new UniqueFile(top, pe));
        }
        return ufiles;
    }

    private final static Set<String> OML_EXTENSIONS = new HashSet<String>(Arrays.asList(OmlConstants.OML_EXTENSIONS));

    private static Collection<PathAndExtension> collectOMLFiles(File directory) throws IOException {
        List<PathAndExtension> omlFiles = new ArrayList<>();
        for (File file : Objects.requireNonNull(directory.listFiles())) {
            if (file.isFile()) {
                String ext = getFileExtension(file);
                if (OML_EXTENSIONS.contains(ext)) {
                    omlFiles.add(new PathAndExtension(file, ext));
                }
            } else if (file.isDirectory()) {
                omlFiles.addAll(collectOMLFiles(file));
            }
        }
        return omlFiles;
    }

    private static String getFileExtension(File file) {
        String fileName = file.getName();
        if (fileName.lastIndexOf(".") != -1)
            return fileName.substring(fileName.lastIndexOf(".") + 1);
        else
            return "";
    }

    /**
     * Get application version id from properties file.
     *
     * @return version string from build.properties or UNKNOWN
     */
    private String getAppVersion() {
    	var version = this.getClass().getPackage().getImplementationVersion();
    	return (version != null) ? version : "<SNAPSHOT>";
    }

    /**
     * A class representing a path and an extension 
     */
    private static class PathAndExtension {
    	private final Path absolutePath;
    	private final String extension;
    	private byte[] hash;

        public PathAndExtension(File file, String extension) throws IOException {
            String path = file.getAbsolutePath();
            this.extension = extension;
            this.absolutePath = new File(path.substring(0, path.length() - 1 - extension.length())).toPath();
            try (FileInputStream fis = new FileInputStream(file)) {
                this.hash = normalizedHash(fis);
            }
        }
    }

    /**
     * A class representing a unique file 
     */
    public static class UniqueFile {
        private final Path top;
        private final Path relativePath;
        private final String extension;
        private final byte[] hash;
        private final List<String> inputs = new ArrayList<>();
        private final List<String> differentInputs = new ArrayList<>();

        /**
         * Creates a new UniqueFile object
         * 
         * @param top the top path
         * @param pe the path and extension
         */
        public UniqueFile(Path top, PathAndExtension pe) {
            this.top = top;
            this.relativePath = top.relativize(pe.absolutePath);
            this.extension = pe.extension;
            this.hash = pe.hash;
        }

        /**
         * Return a string representing an error
         * 
         * @return String
         */
        public String toError() {
            StringBuffer buff = new StringBuffer();
            buff.append("Different contents for path: ").append(relativePath).append(".").append(extension)
            	.append("\nbetween ")
                .append(inputs.size()).append(" equivalent inputs and ")
                .append(differentInputs.size()).append(" different inputs.");
            inputs.forEach(input -> buff.append("\n equivalent content from: ").append(input));
            differentInputs.forEach(input -> buff.append("\n different content from: ").append(input));
            buff.append("\n");
            return buff.toString();
        }
    }

    /**
     * A class representing a collection of input files 
     */
    private static class InputFiles {
    	private final String input;
    	private final Collection<UniqueFile> files;

        public InputFiles(String input, Collection<UniqueFile> files) {
            this.input = input;
            this.files = files;
        }
    }

    /**
     * The validator of the input zip path 
     */
    public static class InputZipPath implements IParameterValidator {
    	/**
    	 * Creates a new InputZipPath object
    	 */
    	public InputZipPath() {
    	}
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            File file = new File(value);
            if (!file.exists() || !file.getName().endsWith(".zip")) {
                throw new ParameterException("Value " + value + " is not a path to an existing ZIP archive file.");
            }
        }
    }

    /**
     * The validator of the input folder path 
     */
    public static class InputFolderPath implements IParameterValidator {
    	/**
    	 * Creates a new InputFolderPath object
    	 */
    	public InputFolderPath() {
    	}
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            File file = new File(value);
            if (!file.exists() || !file.isDirectory()) {
                throw new ParameterException("Value " + value + " is not a path to an existing folder.");
            }
        }
    }

    /**
     * The validator of the input catalog path 
     */
    public static class InputCatalogPath implements IParameterValidator {
    	/**
    	 * Creates a new InputCatalogPath object
    	 */
    	public InputCatalogPath() {
    	}
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            File file = new File(value);
            if (!file.exists() || !file.getName().endsWith("catalog.xml")) {
                throw new ParameterException("Value " + value + " is not a path to an existing catalog.xml");
            }
        }
    }

    /**
     * The validator of the input file path 
     */
    public static class OutputFilePath implements IParameterValidator {
    	/**
    	 * Creates a new OutputFilePath object
    	 */
    	public OutputFilePath() {
    	}
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            new File(value).mkdirs();
        }
    }

}
