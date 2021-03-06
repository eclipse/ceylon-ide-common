/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import org.eclipse.ceylon.common {
    Versions
}
shared Boolean ceylonVersionHasBeenReleased(String version) =>
        !version.endsWith("SNAPSHOT");

shared [String*] versionsAvailableForBoostrap = 
        [ for (version in Versions.jvmVersions*.version)
          if (! version.startsWith("0.") && ceylonVersionHasBeenReleased(version))
          version ]
        .reversed;

