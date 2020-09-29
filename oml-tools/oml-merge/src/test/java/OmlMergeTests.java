import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.junit.AfterClass;
import org.junit.Assert;
import org.junit.BeforeClass;
import org.junit.Test;

import com.beust.jcommander.JCommander;

import io.opencaesar.oml.merge.OmlMergeApp;

public class OmlMergeTests {

    static Path test1_folder1;
    static Path test1_folder2;
    static Path test1_output;

    static Path test2_folder1;
    static Path test2_folder2;
    static Path test2_output;

    static Path test3_folder2;
    static Path test3_output;

    static Path test4_folder2;
    static Path test4_output;
    
    @BeforeClass
    public static void setUp() throws Exception {
        test1_folder1 = Files.createTempDirectory("oml-merge-test1-folder1-");
        test1_folder1.toFile().deleteOnExit();
        test1_folder1.resolve("A/B").toFile().mkdirs();
        test1_folder1.resolve("C").toFile().mkdirs();

        Files.copy(OmlMergeTests.class.getResourceAsStream("/test1/folder1/A/B/c.oml"), test1_folder1.resolve("A/B/c.oml"));
        Files.copy(OmlMergeTests.class.getResourceAsStream("/test1/folder1/C/d.oml"), test1_folder1.resolve("C/d.oml"));

        test1_folder2 = Files.createTempDirectory("oml-merge-test1-folder2-");
        test1_folder2.toFile().deleteOnExit();
        test1_folder2.resolve("A/B").toFile().mkdirs();
        test1_folder2.resolve("C").toFile().mkdirs();

        Files.copy(OmlMergeTests.class.getResourceAsStream("/test1/folder2/A/B/c.oml"), test1_folder2.resolve("A/B/c.oml"));
        Files.copy(OmlMergeTests.class.getResourceAsStream("/test1/folder2/C/d.oml"), test1_folder2.resolve("C/d.oml"));

        test1_output = Files.createTempDirectory("oml-merge-test1-folder12-");
        test1_output.toFile().deleteOnExit();

        test2_folder1 = Files.createTempDirectory("oml-merge-test2-folder1-");
        test2_folder1.toFile().deleteOnExit();
        test2_folder1.resolve("A/B").toFile().mkdirs();
        test2_folder1.resolve("C").toFile().mkdirs();

        Files.copy(OmlMergeTests.class.getResourceAsStream("/test2/folder1/A/B/c.oml"), test2_folder1.resolve("A/B/c.oml"));
        Files.copy(OmlMergeTests.class.getResourceAsStream("/test2/folder1/C/d.oml"), test2_folder1.resolve("C/d.oml"));

        test2_folder2 = Files.createTempDirectory("oml-merge-test2-folder2-");
        test2_folder2.toFile().deleteOnExit();
        test2_folder2.resolve("A/B").toFile().mkdirs();
        test2_folder2.resolve("C").toFile().mkdirs();

        Files.copy(OmlMergeTests.class.getResourceAsStream("/test2/folder2/A/B/c.oml"), test2_folder2.resolve("A/B/c.oml"));
        Files.copy(OmlMergeTests.class.getResourceAsStream("/test2/folder2/C/d.oml"), test2_folder2.resolve("C/d.oml"));

        test2_output = Files.createTempDirectory("oml-merge-test2-folder12-");
        test2_output.toFile().deleteOnExit();

        test3_folder2 = Files.createTempDirectory("oml-merge-test3-folder2-");
        test3_folder2.toFile().deleteOnExit();
        
        Files.copy(OmlMergeTests.class.getResourceAsStream("/test3/folder2.zip"), test3_folder2.resolve("folder2.zip"));

        test3_output = Files.createTempDirectory("oml-merge-test3-folder12-");
        test3_output.toFile().deleteOnExit();
        
        test4_folder2 = Files.createTempDirectory("oml-merge-test4-folder2-");
        test4_folder2.toFile().deleteOnExit();

        Files.copy(OmlMergeTests.class.getResourceAsStream("/test4/folder2.zip"), test4_folder2.resolve("folder2.zip"));

        test4_output = Files.createTempDirectory("oml-merge-test4-folder12-");
        test4_output.toFile().deleteOnExit();
    }

    @AfterClass
    public static void tearDown() throws Exception {
        deleteDirectoryRecursively(test1_folder1.toFile());
        deleteDirectoryRecursively(test1_folder2.toFile());
        deleteDirectoryRecursively(test2_folder1.toFile());
        deleteDirectoryRecursively(test2_folder2.toFile());
        deleteDirectoryRecursively(test3_folder2.toFile());
        deleteDirectoryRecursively(test4_folder2.toFile());
    }
    
    @Test
    public void testMergeIdenticalFolders() throws IOException {
        OmlMergeApp app = new OmlMergeApp();
        final JCommander builder = JCommander.newBuilder().addObject(app).build();
        builder.parse("-f", test1_folder1.toFile().getAbsolutePath(), "-f", test1_folder2.toFile().getAbsolutePath(), "-o", test1_output.toFile().getAbsolutePath(), "-g");
        List<OmlMergeApp.UniqueFile> differences = app.run();
        Assert.assertTrue(differences.isEmpty());
        Set<Path> resultPaths = Files.walk(test1_output).collect(Collectors.toSet());
        Assert.assertTrue(resultPaths.size() == 7);
    }

    @Test
    public void testMergeDifferentFolders() throws IOException {
        OmlMergeApp app = new OmlMergeApp();
        final JCommander builder = JCommander.newBuilder().addObject(app).build();
        builder.parse("-f", test2_folder1.toFile().getAbsolutePath(), "-f", test2_folder2.toFile().getAbsolutePath(), "-o", test2_output.toFile().getAbsolutePath(), "-g");
        List<OmlMergeApp.UniqueFile> differences = app.run();
        Assert.assertTrue(differences.size() == 1);
        Set<Path> resultPaths = Files.walk(test2_output).collect(Collectors.toSet());
        Assert.assertTrue(resultPaths.size() == 7);
    }

    @Test
    public void testMergeIdenticalFolderAndZip() throws IOException {
        OmlMergeApp app = new OmlMergeApp();
        final JCommander builder = JCommander.newBuilder().addObject(app).build();
        builder.parse("-f", test1_folder1.toFile().getAbsolutePath(), "-z", test3_folder2.resolve("folder2.zip").toFile().getAbsolutePath(), "-o", test3_output.toFile().getAbsolutePath(), "-g");
        List<OmlMergeApp.UniqueFile> differences = app.run();
        Assert.assertTrue(differences.isEmpty());
        Set<Path> resultPaths = Files.walk(test3_output).collect(Collectors.toSet());
        Assert.assertTrue(resultPaths.size() == 7);
    }

    @Test
    public void testMergeDifferentFolderAndZip() throws IOException {
        OmlMergeApp app = new OmlMergeApp();
        final JCommander builder = JCommander.newBuilder().addObject(app).build();
        builder.parse("-f", test1_folder1.toFile().getAbsolutePath(), "-z", test4_folder2.resolve("folder2.zip").toFile().getAbsolutePath(), "-o", test4_output.toFile().getAbsolutePath(), "-g");
        List<OmlMergeApp.UniqueFile> differences = app.run();
        Assert.assertTrue(differences.size() == 1);
        Set<Path> resultPaths = Files.walk(test4_output).collect(Collectors.toSet());
        Assert.assertTrue(resultPaths.size() == 7);
    }

    public static void deleteDirectoryRecursively(File dir) {
        if (dir.isDirectory()) {
            File[] files = dir.listFiles();
            if (files != null && files.length > 0) {
                for (File aFile : files) {
                    deleteDirectoryRecursively(aFile);
                }
            }
            dir.delete();
        } else {
            dir.delete();
        }
    }
}
