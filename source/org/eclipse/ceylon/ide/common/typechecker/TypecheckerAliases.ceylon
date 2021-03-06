/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
shared interface TypecheckerAliases<NativeProject, NativeResource, NativeFolder, NativeFile>
        given NativeProject satisfies Object
        given NativeResource satisfies Object
        given NativeFolder satisfies NativeResource
        given NativeFile satisfies NativeResource {
    shared alias ModifiablePhasedUnitAlias => ModifiablePhasedUnit<NativeProject, NativeResource, NativeFolder, NativeFile>;
    shared alias ProjectPhasedUnitAlias => ProjectPhasedUnit<NativeProject, NativeResource, NativeFolder, NativeFile>;
    shared alias EditedPhasedUnitAlias => EditedPhasedUnit<NativeProject, NativeResource, NativeFolder, NativeFile>;
    shared alias CrossProjectPhasedUnitAlias => CrossProjectPhasedUnit<NativeProject, NativeResource, NativeFolder, NativeFile>;
}