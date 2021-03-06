/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import ceylon.collection {
    HashSet,
    ArrayList
}

import org.eclipse.ceylon.compiler.java.loader {
    TypeFactory
}
import org.eclipse.ceylon.compiler.typechecker.tree {
    Visitor,
    Tree
}
import org.eclipse.ceylon.ide.common.platform {
    VfsServicesConsumer
}
import org.eclipse.ceylon.ide.common.typechecker {
    ProjectPhasedUnit
}
import org.eclipse.ceylon.model.cmr {
    JDKUtils
}
import org.eclipse.ceylon.model.typechecker.model {
    Declaration,
    Type,
    TypeDeclaration,
    TypedDeclaration,
    Module,
    Unit,
    Parameter,
    ModelUtil
}
import java.lang {
    Types {
        nativeString
    },
    overloaded
}

class UnitDependencyVisitor<NativeProject, NativeResource, NativeFolder, NativeFile>
            (ProjectPhasedUnit<NativeProject, NativeResource, NativeFolder, NativeFile> thePhasedUnit)
                extends Visitor()
        satisfies ModelAliases<NativeProject, NativeResource, NativeFolder, NativeFile>
                & VfsServicesConsumer<NativeProject, NativeResource, NativeFolder, NativeFile>
        given NativeProject satisfies Object
        given NativeResource satisfies Object
        given NativeFolder satisfies NativeResource
        given NativeFile satisfies NativeResource {
    value phasedUnit = thePhasedUnit;
    value alreadyDone = HashSet<Declaration>();
    
    void storeTypeDependency(Type? type) {
        if (exists type) {
            if (type.classOrInterface || 
                type.typeAlias) {
                if (!createDependency(type.declaration)) {
                    return;
                }
            }
            storeTypeDependency(type.extendedType);
            for (st in type.satisfiedTypes) {
                storeTypeDependency(st);
            }
            if (exists caseTypes = 
                    type.caseTypes) {
                for (ct in caseTypes) {
                    storeTypeDependency(ct);
                }
            }
        }
    }
    
    void storeDeclarationDependency(Declaration? dec) {
        switch (dec)
        case (is TypeDeclaration) {
            storeTypeDeclarationDependency(dec); 
        }
        case (is TypedDeclaration) {
            storeTypedDeclarationDependency(dec); 
        }
        else {}
    }
    
    void storeTypedDeclarationDependency(TypedDeclaration dec) {
        storeTypeDependency(dec.type);
        //TODO: parameters!
        if (is TypedDeclaration rd = dec.refinedDeclaration,
            rd!=dec) {
            storeTypedDeclarationDependency(rd); //this one is needed for default arguments, I think
        }
        createDependency(dec);
    }
    
    void storeTypeDeclarationDependency(TypeDeclaration dec) {
        TypeDeclaration typeDeclaration = dec;
        storeTypeDependency(typeDeclaration.type);
        if (is TypeDeclaration rd = dec.refinedDeclaration,
            ! (rd === dec)) {
            storeTypeDeclarationDependency(rd); //this one is needed for default arguments, I think
        }
        createDependency(dec);
    }
    
    Boolean createDependency(Declaration? dec) {
        if (exists dec,
            ! dec in alreadyDone) {
            alreadyDone.add(dec);
            if (exists declarationUnit = dec.unit, 
                !(declarationUnit is TypeFactory)) {
                String moduleName = 
                        declarationUnit.\ipackage
                        .\imodule
                        .nameAsString;
                if (moduleName != Module.languageModuleName, 
                    !JDKUtils.isJDKModule(moduleName),
                    !JDKUtils.isOracleJDKModule(moduleName),
                    exists currentUnitProjectRelativePath = phasedUnit.unitFile.projectRelativePath) {
                    addDependentsOf(declarationUnit, phasedUnit.unit,
                        currentUnitProjectRelativePath.string);
                }
            }
            return true;
        }
        else {
            return false;
        }
    }
    
    void addDependentsOf(Unit declarationUnit, Unit currentUnit,
        String currentUnitPath) {
        String currentUnitName = currentUnit.filename;
        String dependedOnUnitName = declarationUnit.filename;
        String currentUnitPackage = currentUnit.\ipackage.nameAsString;
        String dependedOnPackage = declarationUnit.\ipackage.nameAsString;
        if (dependedOnUnitName != currentUnitName ||
            dependedOnPackage != currentUnitPackage) {

            switch (declarationUnit)
            else case (is ProjectSourceFileAlias) {
                declarationUnit.dependentsOf
                        .add(nativeString(currentUnitPath));
            }
            else case (is ICrossProjectReferenceAlias) {
                if (exists originalUnit =
                        declarationUnit.originalSourceFile) {
                    originalUnit.dependentsOf
                            .add(nativeString(currentUnitPath));
                }
            }
            else case (is ExternalSourceFile) {
                // Don't manage them : they cannot change ... Well they might if we were using these dependencies to manage module 
                // removal. But since module removal triggers a classpath container update and so a full build, it's not necessary.
                // Might change in the future 
            }
            else case (is CeylonBinaryUnitAlias) {
                declarationUnit.dependentsOf.add(nativeString(currentUnitPath));
            }
            else case (is JavaCompilationUnitAlias) {
                    // The cross-project case for Java files has already been managed
                    // as an ICrossProjectReferenceAlias
                    declarationUnit.dependentsOf.add(nativeString(currentUnitPath));
            }
            else case (is JavaClassFileAlias) {
                    //TODO: All the dependencies to class files are also added... It is really useful ?
                    // I assume in the case of the classes in the classes or exploded dirs, it might be,
                    // but not sure it is also used not in the case of jar-located classes
                    declarationUnit.dependentsOf.add(nativeString(currentUnitPath));
            }
            else {}
        }
    }

    overloaded
    shared actual void visit(Tree.MemberOrTypeExpression that) {
        storeDeclarationDependency(that.declaration);
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.NamedArgument that) {
        //TODO: is this really necessary?
        storeParameterDependency(that.parameter);
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.SequencedArgument that) {
        //TODO: is this really necessary?
        storeParameterDependency(that.parameter);
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.PositionalArgument that) {
        //TODO: is this really necessary?
        storeParameterDependency(that.parameter);
        super.visit(that);
    }
    
    void storeParameterDependency(Parameter? parameter) {
        if (exists parameter) {
            storeDeclarationDependency(parameter.model);
        }
    }

    overloaded
    shared actual void visit(Tree.Type that) {
        storeTypeDependency(that.typeModel);
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.ImportMemberOrType that) {
        storeDeclarationDependency(that.declarationModel);
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.TypeArguments that) {
        //TODO: is this really necessary?
        if (exists types = that.typeModels) {
            for (Type? type in types) {
                storeTypeDependency(type);
            }
        }
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.Term that) {
        //TODO: is this really necessary?
        storeTypeDependency(that.typeModel);
        super.visit(that);
    }

    overloaded
    shared actual void visit(Tree.Declaration that) {
        if (exists decl = that.declarationModel,
            decl.native) {
            if (exists headerDeclaration = ModelUtil.getNativeHeader(decl)) {
                value declarationsDependingOn = ArrayList<Declaration>();
                if (! (headerDeclaration === decl)) {
                    declarationsDependingOn.add(headerDeclaration);
                }
                if (exists overloads = headerDeclaration.overloads) {
                    for (overload in overloads) {
                        if (! (overload === decl)) {
                            declarationsDependingOn.add(overload);
                        }
                    }
                }
                for (dependingOn in declarationsDependingOn) {
                    createDependency(dependingOn);
                    if (is JavaCompilationUnitAlias u = dependingOn.unit,
                        exists javaFile = u.resourceFile,
                        exists javaFileProject = u.resourceProject,
                        exists projectRelativePath = vfsServices.getProjectRelativePath(javaFile, javaFileProject)) {

                        addDependentsOf(decl.unit, u, projectRelativePath.string);
                    }
                }
            }
        }
        super.visit(that);
    }
}
