/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import org.eclipse.ceylon.compiler.typechecker.analyzer {
    UsageWarning
}
import org.eclipse.ceylon.compiler.typechecker.parser {
    CeylonParser,
    LexError,
    RecognitionError
}
import org.eclipse.ceylon.compiler.typechecker.tree {
    AnalysisMessage,
    Message,
    Node,
    Tree,
    Visitor
}

import org.antlr.runtime {
    CommonToken
}

shared abstract class ErrorVisitor() extends Visitor() {

    shared variable Boolean warnForErrors = false;
    
    shared actual void visitAny(Node node) {
        super.visitAny(node);
        for (error in node.errors) {
            if (!include(error)) {
                continue;
            }
            
            variable value startOffset = 0;
            variable value endOffset = 0;
            variable value startCol = 0;
            variable value startLine = 0;
            if (is RecognitionError error) {
                value recognitionError = error;
                value re = recognitionError.recognitionException;
                if (is LexError error) {
                    startLine = re.line;
                    startCol = re.charPositionInLine;
                    startOffset = re.index;
                    endOffset = startOffset;
                }
                
                if (is CommonToken token = re.token) {
                    startOffset = token.startIndex;
                    endOffset = token.stopIndex + 1;
                    startCol = token.charPositionInLine;
                    startLine = token.line;
                    if (token.type == CeylonParser.eof) {
                        startOffset--;
                        endOffset--;
                    }
                }
            }
            
            if (is AnalysisMessage error) {
                value analysisMessage = error;
                value treeNode = analysisMessage.treeNode;
                value errorNode = nodes.getIdentifyingNode(treeNode)
                                  else treeNode;
                
                if (is CommonToken token = errorNode.token) {
                    startOffset = errorNode.startIndex.intValue();
                    endOffset = errorNode.endIndex.intValue();
                    startCol = token.charPositionInLine;
                    startLine = token.line;
                }
            }
            
            handleMessage(startOffset, endOffset, startCol, startLine, error);
        }
    }
    
    shared formal void handleMessage(Integer startOffset, Integer endOffset,
        Integer startCol, Integer startLine, Message error);
    
    Boolean include(Message msg)
            => if (is UsageWarning msg) then !msg.suppressed else true;
    
    shared actual void visit(Tree.StatementOrArgument that) {
        value owe = warnForErrors;
        warnForErrors = false;
        for (c in that.compilerAnnotations) {
            if (exists id = c.identifier, 
                id.text == "error") {
                warnForErrors = true;
            }
        }
        
        super.visit(that);
        warnForErrors = owe;
    }
}
