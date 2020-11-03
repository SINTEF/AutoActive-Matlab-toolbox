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
package org.apache.commons.compress2.archivers.sevenz;

import org.apache.commons.compress2.archivers.sevenz.SevenZArchiveEntry;
import org.apache.commons.compress2.archivers.sevenz.SevenZMethodConfiguration;
import org.apache.commons.compress2.archivers.sevenz.SevenZMethod;
import org.junit.Assert;
import org.junit.Test;

import java.util.Arrays;

public class SevenZArchiveEntryTest {

    @Test(expected=UnsupportedOperationException.class)
    public void shouldThrowIfNoLastModifiedDateIsSet() {
        new SevenZArchiveEntry().getLastModifiedDate();
    }

    @Test(expected=UnsupportedOperationException.class)
    public void shouldThrowIfNoCreationDateIsSet() {
        new SevenZArchiveEntry().getCreationDate();
    }

    @Test(expected=UnsupportedOperationException.class)
    public void shouldThrowIfNoAccessDateIsSet() {
        new SevenZArchiveEntry().getAccessDate();
    }

    @Test
    public void noMethodsIsDifferentFromSomeMethods() {
        SevenZArchiveEntry z1 = new SevenZArchiveEntry();
        SevenZArchiveEntry z2 = new SevenZArchiveEntry();
        z2.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.COPY)));
        Assert.assertNotEquals(z1, z2);
        Assert.assertNotEquals(z2, z1);
    }

    @Test
    public void oneMethodsIsDifferentFromTwoMethods() {
        SevenZArchiveEntry z1 = new SevenZArchiveEntry();
        SevenZArchiveEntry z2 = new SevenZArchiveEntry();
        z1.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.COPY)));
        z2.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.DELTA_FILTER),
                                           new SevenZMethodConfiguration(SevenZMethod.LZMA2)));
        Assert.assertNotEquals(z1, z2);
        Assert.assertNotEquals(z2, z1);
    }

    @Test
    public void sameMethodsYieldEqualEntries() {
        SevenZArchiveEntry z1 = new SevenZArchiveEntry();
        SevenZArchiveEntry z2 = new SevenZArchiveEntry();
        z1.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.DELTA_FILTER),
                                           new SevenZMethodConfiguration(SevenZMethod.LZMA2)));
        z2.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.DELTA_FILTER),
                                           new SevenZMethodConfiguration(SevenZMethod.LZMA2)));
        Assert.assertEquals(z1, z2);
        Assert.assertEquals(z2, z1);
    }

    @Test
    public void methodOrderMattersInEquals() {
        SevenZArchiveEntry z1 = new SevenZArchiveEntry();
        SevenZArchiveEntry z2 = new SevenZArchiveEntry();
        z1.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.LZMA2),
                                           new SevenZMethodConfiguration(SevenZMethod.DELTA_FILTER)));
        z2.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.DELTA_FILTER),
                                           new SevenZMethodConfiguration(SevenZMethod.LZMA2)));
        Assert.assertNotEquals(z1, z2);
        Assert.assertNotEquals(z2, z1);
    }

    @Test
    public void methodConfigurationMattersInEquals() {
        SevenZArchiveEntry z1 = new SevenZArchiveEntry();
        SevenZArchiveEntry z2 = new SevenZArchiveEntry();
        SevenZArchiveEntry z3 = new SevenZArchiveEntry();
        z1.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.LZMA2, 1)));
        z2.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.LZMA2, 2)));
        z3.setContentMethods(Arrays.asList(new SevenZMethodConfiguration(SevenZMethod.LZMA2, 2)));
        Assert.assertNotEquals(z1, z2);
        Assert.assertNotEquals(z2, z1);
        Assert.assertEquals(z3, z2);
        Assert.assertEquals(z2, z3);
    }

}
