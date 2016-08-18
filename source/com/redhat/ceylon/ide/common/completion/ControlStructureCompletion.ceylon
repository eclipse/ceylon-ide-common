import com.redhat.ceylon.compiler.typechecker.tree {
    Node
}
import com.redhat.ceylon.ide.common.platform {
    CommonDocument,
    platformServices
}
import com.redhat.ceylon.ide.common.refactoring {
    DefaultRegion
}
import com.redhat.ceylon.ide.common.typechecker {
    LocalAnalysisResult
}
import com.redhat.ceylon.ide.common.util {
    singularize
}
import com.redhat.ceylon.model.typechecker.model {
    Declaration,
    DeclarationWithProximity,
    Value
}

shared interface ControlStructureCompletionProposal {
    
    shared void addForProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp, Declaration d) {
        
        if (is Value d,
            exists t = d.type,
            d.unit.isIterableType(t) ||
            d.unit.isJavaIterableType(t) ||
            d.unit.isJavaArrayType(t)) {
            value name = d.name;
            value elemName =
                    switch (name.size)
                    case (1) "element"
                    case (2) if (name.endsWith("s"))
                        then name.spanTo(0)
                        else "element"
                    else let (singular = singularize(name))
                        if (singular==name)
                        then "element"
                        else singular;

            value unit = ctx.lastCompilationUnit.unit;
            value desc = "for (``elemName`` in ``getDescriptionFor(d, unit)``)";
            value text = "for (``elemName`` in ``getTextFor(d, unit)``) {}";

            platformServices.completion
                .newControlStructureCompletionProposal(offset, prefix, desc, text, d, ctx);
        }
    }
    
    shared void addIfExistsProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp,
        Declaration d, Node? node = null, String? forcedText = null) {
        
        if (!dwp.unimported,
            is Value d,
            exists type = d.type,
            d.unit.isOptionalType(type),
            !d.variable) {
            value unit = ctx.lastCompilationUnit.unit;
            value desc = "if (exists ``forcedText else getDescriptionFor(d, unit)``)";
            value text = "if (exists ``forcedText else getTextFor(d, unit)``) {}";

            platformServices.completion
                .newControlStructureCompletionProposal(offset, prefix, desc, text, d, ctx, node);
        }
    }
    
    shared void addAssertExistsProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp, Declaration d) {
        
        if (!dwp.unimported,
            is Value d,
            d.type exists,
            d.unit.isOptionalType(d.type),
            !d.variable) {
            value unit = ctx.lastCompilationUnit.unit;
            platformServices.completion.newControlStructureCompletionProposal(offset, prefix,
                    "assert (exists ``getDescriptionFor(d, unit)``)",
                    "assert (exists ``getTextFor(d, unit)``);", d, ctx);
        }
    }
    
    shared void addIfNonemptyProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp, Declaration d) {
        
        if (!dwp.unimported,
            is Value d,
            exists type = d.type,
            d.unit.isPossiblyEmptyType(type),
            !d.variable) {
            value unit = ctx.lastCompilationUnit.unit;
            value desc = "if (nonempty ``getDescriptionFor(d, unit)``)";
            value text = "if (nonempty ``getTextFor(d, unit)``) {}";
            platformServices.completion
                .newControlStructureCompletionProposal(offset, prefix, desc, text, d, ctx);
        }
    }
    
    shared void addAssertNonemptyProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp, Declaration d) {
        
        if (!dwp.unimported,
            is Value d,
            d.type exists,
            d.unit.isPossiblyEmptyType(d.type),
            !d.variable) {
            value unit = ctx.lastCompilationUnit.unit;
            platformServices.completion
                .newControlStructureCompletionProposal(offset, prefix,
                    "assert (nonempty ``getDescriptionFor(d, unit)``)",
                    "assert (nonempty ``getTextFor(d, unit)``);",
                    d, ctx);
        }
    }
    
    shared void addTryProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp, Declaration d) {
        
        if (!dwp.unimported,
            is Value d,
            exists type = d.type,
            d.type.declaration.inherits(d.unit.obtainableDeclaration),
            !d.variable) {
            value unit = ctx.lastCompilationUnit.unit;
            value desc = "try (``getDescriptionFor(d, unit)``)";
            value text = "try (``getTextFor(d, unit)``) {}";

            platformServices.completion
                .newControlStructureCompletionProposal(offset, prefix, desc, text, d, ctx);
        }
    }
    
    shared void addSwitchProposal(Integer offset, String prefix, CompletionContext ctx,
        DeclarationWithProximity dwp, Declaration d, Node node) {
        
        if (!dwp.unimported,
            is Value d,
            exists type = d.type,
            exists caseTypes = d.type.caseTypes,
            !d.variable) {
            value body = StringBuilder();
            value indent = ctx.commonDocument.getIndent(node);
            value unit = node.unit;
            for (pt in caseTypes) {
                body.append(indent).append("case (");
                value ctd = pt.declaration;
                if (ctd.anonymous) {
                    if (!ctd.toplevel) {
                        body.append(type.declaration.getName(unit)).append(".");
                    }
                    body.append(ctd.getName(unit));
                } else {
                    body.append("is ").append(pt.asSourceCodeString(unit));
                }
                body.append(") {}").append(ctx.commonDocument.defaultLineDelimiter);
            }
            body.append(indent);
            value u = ctx.lastCompilationUnit.unit;
            value desc = "switch (``getDescriptionFor(d, u)``)";
            value text = "switch (``getTextFor(d, u)``)"
                    + ctx.commonDocument.defaultLineDelimiter + body.string;
            platformServices.completion
                .newControlStructureCompletionProposal(offset, prefix, desc, text, d, ctx);
        }
    }
}

shared abstract class ControlStructureProposal
        (Integer offset, String prefix, String desc, String text,
            Node? node, Declaration dec, LocalAnalysisResult cpc)
        
        extends AbstractCompletionProposal(offset, prefix, desc, text) {

    shared actual DefaultRegion getSelectionInternal(CommonDocument document) {
        value loc = (text.firstOccurrence('{') else text.firstOccurrence(';') else -1) + 1;
        return DefaultRegion(offset + loc - prefix.size, 0);
    }
}