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
import org.apache.commons.compress2.archivers.zip.UnixStat;
import org.apache.commons.compress2.archivers.zip.ZipArchiveEntry;
import org.apache.commons.compress2.archivers.zip.ZipArchiveEntryRequestSupplier;
import org.apache.commons.compress2.archivers.zip.ScatterZipOutputStream;
import org.apache.commons.compress2.archivers.zip.ZipArchiveEntryRequest;
import org.apache.commons.compress2.archivers.zip.ZipArchiveOutputStream;
import org.apache.commons.compress2.archivers.zip.ParallelScatterZipCreator;
import org.apache.commons.compress2.parallel.FileBasedScatterGatherBackingStore;
import org.apache.commons.compress2.parallel.InputStreamSupplier;
import org.apache.commons.compress2.parallel.ScatterGatherBackingStore;
import org.apache.commons.compress2.parallel.ScatterGatherBackingStoreSupplier;
import org.apache.commons.compress2.utils.IOUtils;
import org.junit.After;
import org.junit.Test;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.zip.ZipEntry;

import static org.apache.commons.compress2.AbstractTestCase.tryHardToDelete;
import static org.junit.Assert.*;

public class ParallelScatterZipCreatorTest {

    private final int NUMITEMS = 5000;

    private File result;
    private File tmp;

    @After
    public void cleanup() {
        tryHardToDelete(result);
        tryHardToDelete(tmp);
    }

    @Test
    public void concurrent()
            throws Exception {
        result = File.createTempFile("parallelScatterGather1", "");
        final ZipArchiveOutputStream zos = new ZipArchiveOutputStream(result);
        zos.setEncoding("UTF-8");
        final ParallelScatterZipCreator zipCreator = new ParallelScatterZipCreator();

        final Map<String, byte[]> entries = writeEntries(zipCreator);
        zipCreator.writeTo(zos);
        zos.close();
        removeEntriesFoundInZipFile(result, entries);
        assertTrue(entries.size() == 0);
        assertNotNull( zipCreator.getStatisticsMessage());
    }

    @Test
    public void callableApiUsingSubmit() throws Exception {
        result = File.createTempFile("parallelScatterGather2", "");
        callableApi(new CallableConsumerSupplier() {
            @Override
            public CallableConsumer apply(final ParallelScatterZipCreator zipCreator) {
                return new CallableConsumer() {
                    @Override
                    public void accept(Callable<? extends ScatterZipOutputStream> c) {
                        zipCreator.submit(c);
                    }
                };
            }
        });
    }

    @Test
    public void callableApiUsingSubmitStreamAwareCallable() throws Exception {
        result = File.createTempFile("parallelScatterGather3", "");
        callableApi(new CallableConsumerSupplier() {
            @Override
            public CallableConsumer apply(final ParallelScatterZipCreator zipCreator) {
                return new CallableConsumer() {
                    @Override
                    public void accept(Callable<? extends ScatterZipOutputStream> c) {
                        zipCreator.submitStreamAwareCallable(c);
                    }
                };
            }
        });
    }

    private void callableApi(CallableConsumerSupplier consumerSupplier) throws Exception {
        final ZipArchiveOutputStream zos = new ZipArchiveOutputStream(result);
        zos.setEncoding("UTF-8");
        final ExecutorService es = Executors.newFixedThreadPool(1);

        final ScatterGatherBackingStoreSupplier supp = new ScatterGatherBackingStoreSupplier() {
            @Override
            public ScatterGatherBackingStore get() throws IOException {
                return new FileBasedScatterGatherBackingStore(tmp = File.createTempFile("parallelscatter", "n1"));
            }
        };

        final ParallelScatterZipCreator zipCreator = new ParallelScatterZipCreator(es, supp);
        final Map<String, byte[]> entries = writeEntriesAsCallable(zipCreator, consumerSupplier.apply(zipCreator));
        zipCreator.writeTo(zos);
        zos.close();


        removeEntriesFoundInZipFile(result, entries);
        assertTrue(entries.size() == 0);
        assertNotNull(zipCreator.getStatisticsMessage());
    }

    private void removeEntriesFoundInZipFile(final File result, final Map<String, byte[]> entries) throws IOException {
        final ZipFile zf = new ZipFile(result);
        final Enumeration<ZipArchiveEntry> entriesInPhysicalOrder = zf.getEntriesInPhysicalOrder();
        int i = 0;
        while (entriesInPhysicalOrder.hasMoreElements()){
            final ZipArchiveEntry zipArchiveEntry = entriesInPhysicalOrder.nextElement();
            final InputStream inputStream = zf.getInputStream(zipArchiveEntry);
            final byte[] actual = IOUtils.toByteArray(inputStream);
            final byte[] expected = entries.remove(zipArchiveEntry.getName());
            assertArrayEquals( "For " + zipArchiveEntry.getName(),  expected, actual);
            // check order of zip entries vs order of order of addition to the parallel zip creator
            assertEquals( "For " + zipArchiveEntry.getName(),  "file" + i++, zipArchiveEntry.getName());
        }
        zf.close();
    }

    private Map<String, byte[]> writeEntries(final ParallelScatterZipCreator zipCreator) {
        final Map<String, byte[]> entries = new HashMap<>();
        for (int i = 0; i < NUMITEMS; i++){
            final byte[] payloadBytes = ("content" + i).getBytes();
            final ZipArchiveEntry za = createZipArchiveEntry(entries, i, payloadBytes);
            final InputStreamSupplier iss = new InputStreamSupplier() {
                @Override
                public InputStream get() {
                    return new ByteArrayInputStream(payloadBytes);
                }
            };
            if (i % 2 == 0) {
                zipCreator.addArchiveEntry(za, iss);
            } else {
                final ZipArchiveEntryRequestSupplier zaSupplier = new ZipArchiveEntryRequestSupplier() {
                    @Override
                    public ZipArchiveEntryRequest get() {
                        return ZipArchiveEntryRequest.createZipArchiveEntryRequest(za, iss);
                    }
                };
                zipCreator.addArchiveEntry(zaSupplier);
            }
        }
        return entries;
    }

    private Map<String, byte[]> writeEntriesAsCallable(final ParallelScatterZipCreator zipCreator,
                                                       final CallableConsumer consumer) {
        final Map<String, byte[]> entries = new HashMap<>();
        for (int i = 0; i < NUMITEMS; i++){
            final byte[] payloadBytes = ("content" + i).getBytes();
            final ZipArchiveEntry za = createZipArchiveEntry(entries, i, payloadBytes);
            final InputStreamSupplier iss = new InputStreamSupplier() {
                @Override
                public InputStream get() {
                    return new ByteArrayInputStream(payloadBytes);
                }
            };
            final Callable<ScatterZipOutputStream> callable;
            if (i % 2 == 0) {
                callable = zipCreator.createCallable(za, iss);
            } else {
                final ZipArchiveEntryRequestSupplier zaSupplier = new ZipArchiveEntryRequestSupplier() {
                    @Override
                    public ZipArchiveEntryRequest get() {
                        return ZipArchiveEntryRequest.createZipArchiveEntryRequest(za, iss);
                    }
                };
                callable = zipCreator.createCallable(zaSupplier);
            }

            consumer.accept(callable);
        }
        return entries;
    }

    private ZipArchiveEntry createZipArchiveEntry(final Map<String, byte[]> entries, final int i, final byte[] payloadBytes) {
        final ZipArchiveEntry za = new ZipArchiveEntry( "file" + i);
        entries.put( za.getName(), payloadBytes);
        za.setMethod(ZipEntry.DEFLATED);
        za.setSize(payloadBytes.length);
        za.setUnixMode(UnixStat.FILE_FLAG | 0664);
        return za;
    }

    private interface CallableConsumer {
        void accept(Callable<? extends ScatterZipOutputStream> c);
    }
    private interface CallableConsumerSupplier {
        CallableConsumer apply(ParallelScatterZipCreator zipCreator);
    }
}
