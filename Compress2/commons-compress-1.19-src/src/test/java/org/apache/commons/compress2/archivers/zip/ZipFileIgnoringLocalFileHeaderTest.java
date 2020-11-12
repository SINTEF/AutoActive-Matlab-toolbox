/*
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package org.apache.commons.compress2.archivers.zip;

import org.apache.commons.compress2.archivers.zip.ZipFile;
import org.apache.commons.compress2.archivers.zip.ZipEncodingHelper;
import org.apache.commons.compress2.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress2.AbstractTestCase;
import org.apache.commons.compress2.utils.IOUtils;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Enumeration;

public class ZipFileIgnoringLocalFileHeaderTest {

    private File dir;

    @Before
    public void setUp() throws Exception {
        dir = AbstractTestCase.mkdir("dir");
    }

    @After
    public void tearDown() throws Exception {
        AbstractTestCase.rmdir(dir);
    }

    /**
     * Simple unarchive test. Asserts nothing.
     * @throws Exception
     */
    @Test
    public void testZipUnarchive() throws Exception {
        try (final ZipFile zf = openZipWithoutLFH("bla.zip")) {
            for (Enumeration<ZipArchiveEntry> e = zf.getEntries(); e.hasMoreElements(); ) {
                ZipArchiveEntry entry = e.nextElement();
                try (final OutputStream out = new FileOutputStream(new File(dir, entry.getName()))) {
                    IOUtils.copy(zf.getInputStream(entry), out);
                }
            }
        }
    }

    @Test
    public void getEntryWorks() throws IOException {
        try (final ZipFile zf = openZipWithoutLFH("bla.zip")) {
            ZipArchiveEntry ze = zf.getEntry("test1.xml");
            Assert.assertEquals(610, ze.getSize());
        }
    }

    @Test
    public void testDuplicateEntry() throws Exception {
        try (final ZipFile zf = openZipWithoutLFH("COMPRESS-227.zip")) {
            int numberOfEntries = 0;
            for (final ZipArchiveEntry entry : zf.getEntries("test1.txt")) {
                numberOfEntries++;
                Assert.assertNotNull(zf.getInputStream(entry));
            }
            Assert.assertEquals(2, numberOfEntries);
        }
    }

    @Test
    public void getRawInputStreamReturnsNull() throws IOException {
        try (final ZipFile zf = openZipWithoutLFH("bla.zip")) {
            ZipArchiveEntry ze = zf.getEntry("test1.xml");
            Assert.assertNull(zf.getRawInputStream(ze));
        }
    }

    @Test
    public void testPhysicalOrder() throws IOException {
        try (final ZipFile zf = openZipWithoutLFH("ordertest.zip")) {
            Enumeration<ZipArchiveEntry> e = zf.getEntriesInPhysicalOrder();
            ZipArchiveEntry ze = null;
            do {
                ze = e.nextElement();
            } while (e.hasMoreElements());
            Assert.assertEquals("src/main/java/org/apache/commons/compress/archivers/zip/ZipUtil.java", ze.getName());
        }
    }

    private static ZipFile openZipWithoutLFH(String fileName) throws IOException {
        return new ZipFile(AbstractTestCase.getFile(fileName), ZipEncodingHelper.UTF8, true, true);
    }
}
