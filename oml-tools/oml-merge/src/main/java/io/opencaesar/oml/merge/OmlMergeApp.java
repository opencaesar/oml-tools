package io.opencaesar.oml.merge;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;
import com.google.common.io.CharStreams;
import org.apache.log4j.Appender;
import org.apache.log4j.AppenderSkeleton;
import org.apache.log4j.Level;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;
import java.util.stream.Collectors;
import java.util.zip.CRC32;
import java.util.zip.CheckedInputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class OmlMergeApp {

    @Parameter(
            names = {"--input-zip-path", "-z"},
            description = "Paths to OML zip archives (Not required)",
            validateWith = InputZipPath.class,
            order = 1)
    private List<String> inputZipPaths = new ArrayList<>();

    @Parameter(
            names = {"--input-folder-path", "-f"},
            description = "Paths to OML folders (Not required)",
            validateWith = InputFolderPath.class,
            order = 2)
    private List<String> inputFolderPaths = new ArrayList<>();

    @Parameter(
            names = {"--input-catalog-path", "-c"},
            description = "Paths to OML input catalog files (Required)",
            validateWith = InputCatalogPath.class,
            order = 3)
    private List<String> inputCatalogPaths = new ArrayList<>();

    @Parameter(
            names = {"--output-folder-path", "-o"},
            description = "Path to OML output folder where a basic OML catalog will be created (Required)",
            validateWith = OutputFilePath.class,
            required = true,
            order = 4)
    private String outputFolderPath = null;

    @Parameter(
            names = {"--generate-output-catalog", "-g"},
            description = "Generate a catalog file in the output folder path",
            order = 5)
    private boolean generateOutputCatalog;

    @Parameter(
            names = {"--debug", "-d"},
            description = "Shows debug logging statements",
            order = 6)
    private boolean debug;

    @Parameter(
            names = {"--help", "-h"},
            description = "Displays summary of options",
            help = true,
            order = 7)
    private boolean help;

    private final Logger LOGGER = Logger.getLogger(OmlMergeApp.class);

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
	        File outputCatalogFile = outputFolder.toPath().resolve("oml.catalog.xml").toFile();
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
            allInputs.add(new InputFiles(inputZipPath, dir, ufs));
        }

        for (String inputFolderPath : inputFolderPaths) {
            File dir = new File(inputFolderPath);
            Collection<UniqueFile> ufs = collectOMLUniqueFiles(dir);
            allInputs.add(new InputFiles(inputFolderPath, dir.toPath(), ufs));
        }

        for (String inputCatalogPath : inputCatalogPaths) {
            File inputCatalogFile = new File(inputCatalogPath);
            File inputFolder = inputCatalogFile.getParentFile();
            Collection<UniqueFile> ufs = collectOMLUniqueFiles(inputFolder);
            allInputs.add(new InputFiles(inputCatalogPath, inputFolder.toPath(), ufs));
        }

        Map<Path, UniqueFile> uniqueFiles = new HashMap<>();

        allInputs.forEach((InputFiles inputFiles) -> {
            inputFiles.files.forEach((UniqueFile f) -> {
                if (!uniqueFiles.containsKey(f.relativePath)) {
                    f.inputs.add(inputFiles.input);
                    uniqueFiles.put(f.relativePath, f);
                } else {
                    UniqueFile uf = uniqueFiles.get(f.relativePath);
                    if (uf.extension.equals(f.extension) && uf.checksum == f.checksum)
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

    public static long fileChecksum(File f) throws IOException {
        FileInputStream fileInput = new FileInputStream(f);
        byte[] buffer = new byte[1024];
        CheckedInputStream cis = new CheckedInputStream(fileInput, new CRC32());
        while (cis.read(buffer, 0, buffer.length) > 0) {
        }
        long value = cis.getChecksum().getValue();
        cis.close();
        return value;
    }

    public static Collection<UniqueFile> collectOMLUniqueFiles(File directory) throws IOException {
        Path top = directory.toPath();
        Collection<UniqueFile> ufiles = new ArrayList<>();
        for (PathAndExtension pe : collectOMLFiles(directory)) {
            ufiles.add(new UniqueFile(top, pe));
        }
        return ufiles;
    }

    public final static String OML = "oml";
    public final static String OMLXMI = "omlxmi";

    public static Collection<PathAndExtension> collectOMLFiles(File directory) throws IOException {
        List<PathAndExtension> omlFiles = new ArrayList<>();
        for (File file : Objects.requireNonNull(directory.listFiles())) {
            if (file.isFile()) {
                String ext = getFileExtension(file);
                if (ext.equals(OML)) {
                    omlFiles.add(new PathAndExtension(file, ext));
                } else if (ext.equals(OMLXMI)) {
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
    public String getAppVersion() {
        String version = "UNKNOWN";
        try {
            InputStream input = Thread.currentThread().getContextClassLoader().getResourceAsStream("version.txt");
            if (null != input) {
                InputStreamReader reader = new InputStreamReader(input);
                version = CharStreams.toString(reader);
            }
        } catch (IOException e) {
            String errorMsg = "Could not read version.txt file." + e;
            LOGGER.error(errorMsg, e);
        }
        return version;
    }

    public static class PathAndExtension {
        public final Path absolutePath;
        public final String extension;
        public long checksum;

        public PathAndExtension(File file, String extension) throws IOException {
            String path = file.getAbsolutePath();
            this.extension = extension;
            this.absolutePath = new File(path.substring(0, path.length() - 1 - extension.length())).toPath();
            this.checksum = fileChecksum(file);
        }
    }

    public static class UniqueFile {
        public final Path top;
        public final Path relativePath;
        public final String extension;
        public final long checksum;
        public final List<String> inputs = new ArrayList<>();
        public final List<String> differentInputs = new ArrayList<>();

        public UniqueFile(Path top, PathAndExtension pe) {
            this.top = top;
            this.relativePath = top.relativize(pe.absolutePath);
            this.extension = pe.extension;
            this.checksum = pe.checksum;
        }

        public String toError() {
            StringBuffer buff = new StringBuffer();
            buff
                    .append("Different contents for path: ").append(relativePath).append(".").append(extension)
                    .append("\nbetween ")
                    .append(inputs.size()).append(" equivalent inputs and ")
                    .append(differentInputs.size()).append(" different inputs.");
            inputs.forEach(input -> buff.append("\n equivalent content from: ").append(input));
            differentInputs.forEach(input -> buff.append("\n different content from: ").append(input));
            buff.append("\n");
            return buff.toString();
        }
    }

    public static class InputFiles {
        public final String input;
        public final Path top;
        public final Collection<UniqueFile> files;

        public InputFiles(String input, Path top, Collection<UniqueFile> files) {
            this.input = input;
            this.top = top;
            this.files = files;
        }
    }

    public static class InputZipPath implements IParameterValidator {
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            File file = new File(value);
            if (!file.getName().endsWith(".zip") || !file.exists()) {
                throw new ParameterException("Parameter " + name + " should be a path to an existing ZIP archive file.");
            }
        }
    }

    public static class InputFolderPath implements IParameterValidator {
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            File file = new File(value);
            if (!file.exists() || !file.isDirectory()) {
                throw new ParameterException("Parameter " + name + " should be a path to an existing folder.");
            }
        }
    }

    public static class InputCatalogPath implements IParameterValidator {
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            File file = new File(value);
            if (!file.getName().endsWith("catalog.xml") || !file.exists()) {
                throw new ParameterException("Parameter " + name + " should be an existing catalog.xml path");
            }
        }
    }

    public static class OutputFilePath implements IParameterValidator {
        @Override
        public void validate(final String name, final String value) throws ParameterException {
            new File(value).mkdirs();
        }
    }

}
