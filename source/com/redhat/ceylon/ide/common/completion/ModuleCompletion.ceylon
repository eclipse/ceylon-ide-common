import ceylon.collection {
    MutableList,
    naturalOrderTreeSet
}
import ceylon.interop.java {
    CeylonIterable,
    javaString
}

import com.redhat.ceylon.cmr.api {
    ModuleSearchResult {
        ModuleDetails
    },
    ModuleVersionDetails
}
import com.redhat.ceylon.common {
    Versions
}
import com.redhat.ceylon.compiler.typechecker {
    TypeChecker
}
import com.redhat.ceylon.compiler.typechecker.tree {
    Tree,
    Node
}
import com.redhat.ceylon.ide.common.typechecker {
    LocalAnalysisResult
}
import com.redhat.ceylon.ide.common.util {
    ProgressMonitor,
    toCeylonStringIterable,
    moduleQueries,
    nodes
}
import com.redhat.ceylon.model.cmr {
    JDKUtils
}
import com.redhat.ceylon.model.typechecker.model {
    Module
}

import java.lang {
    JInteger=Integer
}

shared interface ModuleCompletion<IdeComponent,IdeArtifact,CompletionComponent,Document>
        given IdeComponent satisfies LocalAnalysisResult<Document,IdeArtifact>
        given IdeArtifact satisfies Object {
    
    shared formal Boolean supportsLinkedModeInArguments;
            
    shared formal CompletionComponent newModuleProposal(Integer offset, String prefix, Integer len, 
                String versioned, ModuleDetails mod,
                Boolean withBody, ModuleVersionDetails version, String name, Node node);

    shared formal CompletionComponent newModuleDescriptorProposal(Integer offset, String prefix, String name); 
            
    shared formal CompletionComponent newJDKModuleProposal(Integer offset, String prefix, Integer len, 
                String versioned, String name);

    shared void addModuleDescriptorCompletion(IdeComponent cpc, Integer offset, String prefix, MutableList<CompletionComponent> result) {
        print("coin");
        if (!"module".startsWith(prefix)) {
            return;
        }
        value moduleName = getPackageName(cpc.rootNode);
        if (exists moduleName) {
            print("coin2--=``moduleName``");
            result.add(newModuleDescriptorProposal(offset, prefix, moduleName));
        }
    }

    shared void addModuleCompletions(IdeComponent cpc, Integer offset, String prefix, Tree.ImportPath? path, Node node, 
            MutableList<CompletionComponent> result, Boolean withBody, ProgressMonitor monitor) {
        value fp = fullPath(offset, prefix, path);

        addModuleCompletionsInternal(offset, prefix, node, result, fp.size, fp + prefix, cpc, withBody, monitor);
    }

    void addModuleCompletionsInternal(Integer offset, String prefix, Node node, MutableList<CompletionComponent> result, 
            Integer len, String pfp, IdeComponent cpc, Boolean withBody, ProgressMonitor monitor) {

        if (pfp.startsWith("java.")) {
            for (name in naturalOrderTreeSet<String>(toCeylonStringIterable(JDKUtils.jdkModuleNames))) {
                if (name.startsWith(pfp), !moduleAlreadyImported(cpc, name)) {
                    result.add(newJDKModuleProposal(offset, prefix, len, getModuleString(withBody, name, JDKUtils.jdk.version), name));
                }
            }
        } else {
            TypeChecker? typeChecker = cpc.typeChecker;
            if (exists typeChecker) {
                value project = cpc.ceylonProject;
                monitor.subTask("querying module repositories...");
                value query = moduleQueries.getModuleQuery(pfp, project);
                query.binaryMajor = JInteger(Versions.\iJVM_BINARY_MAJOR_VERSION);
                ModuleSearchResult? results = typeChecker.context.repositoryManager.completeModules(query);
                monitor.subTask(null);
                //                final ModuleSearchResult results = 
                //                        getModuleSearchResults(pfp, typeChecker,project);
                if (!exists results) {
                    return;
                }
                assert(exists results);
                for (\imodule in CeylonIterable(results.results)) {
                    value name = \imodule.name;
                    if (!name.equals(Module.\iDEFAULT_MODULE_NAME), !moduleAlreadyImported(cpc, name)) {
                        if (supportsLinkedModeInArguments) {
                            result.add(newModuleProposal(offset, prefix, len, getModuleString(withBody, name, \imodule.lastVersion.version),
                                \imodule, withBody, \imodule.lastVersion, name, node));
                        } else {
                            for (version in CeylonIterable(\imodule.versions.descendingSet())) {
                                result.add(newModuleProposal(offset, prefix, len, getModuleString(withBody, name, version.version),
                                    \imodule, withBody, version, name, node));
                            }
                        }
                    }
                }
            }
        }
    }

    Boolean moduleAlreadyImported(IdeComponent cpc, String mod) {
        if (mod.equals(Module.\iLANGUAGE_MODULE_NAME)) {
            return true;
        }
        value md = cpc.rootNode.moduleDescriptors;
        if (!md.empty) {
            Tree.ImportModuleList? iml = md.get(0).importModuleList;
            if (exists iml) {
                for (im in CeylonIterable(iml.importModules)) {
                    value path = nodes.getImportedName(im);
                    if (exists path, path.equals(mod)) {
                        return true;
                    }
                }
            }
        }
        //Disabled, because once the module is imported, it hangs around!
        //        for (ModuleImport mi: node.getUnit().getPackage().getModule().getImports()) {
        //            if (mi.getModule().getNameAsString().equals(mod)) {
        //                return true;
        //            }
        //        }
        return false;
    }

    String getModuleString(Boolean withBody, variable String name, String version) {
        if (!javaString(name).matches("^[a-z_]\\w*(\\.[a-z_]\\w*)*$")) {
            name = "\"``name``\"";
        }
        return if (withBody) then name + " \"" + version + "\";" else name;
    }

}