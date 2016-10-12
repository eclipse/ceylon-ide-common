import com.redhat.ceylon.compiler.typechecker.tree {
    Node,
    Tree,
    Visitor
}
import com.redhat.ceylon.model.typechecker.model {
    Parameter,
    TypedDeclaration
}

shared class FindInvocationVisitor(Node node) extends Visitor() {
    
    shared variable Tree.InvocationExpression? result = null;
    variable Tree.InvocationExpression? current = null;
    shared variable TypedDeclaration? parameter = null;
    
    shared actual void visit(Tree.ListedArgument that) {
        Tree.Expression? e = that.expression;
        if (exists e,
            exists term = e.term,
            node == term) {
            result = current;
            Parameter? p = that.parameter;
            if (exists p) {
                parameter = p.model;
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.SpreadArgument that) {
        Tree.Expression? e = that.expression;
        if (exists e,
            exists term = e.term,
            node == term) {
            result = current;
            Parameter? p = that.parameter;
            if (exists p) {
                parameter = p.model;
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.NamedArgument that) {
        if (node == that) {
            result = current;
            Parameter? p = that.parameter;
            if (exists p) {
                parameter = p.model;
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.Return that) {
        Tree.Expression? e = that.expression;
        if (exists e,
            exists term = e.term,
            node == term) {
            //result=current;
            assert(is TypedDeclaration decl = that.declaration);
            parameter = decl;
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.AssignOp that) {
        if (exists rightTerm = that.rightTerm,
            node == rightTerm) {
            //result=current;
            if (is Tree.BaseMemberExpression lt =
                    that.leftTerm) {
                if (is TypedDeclaration d =
                        lt.declaration) {
                    parameter = d;
                }
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.SpecifierStatement that) {
        Tree.Expression? e = that.specifierExpression.expression;
        if (exists e,
            exists term = e.term,
            node == term,
            is Tree.BaseMemberExpression bme = that.baseMemberExpression,
            is TypedDeclaration d = bme.declaration) {
            parameter = d;
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.AttributeDeclaration that) {
        if (exists sie= that.specifierOrInitializerExpression) {
            if (exists e = sie.expression,
                exists term = e.term,
                node == term) {
                parameter = that.declarationModel;
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.MethodDeclaration that) {
        if (exists sie = that.specifierExpression) {
            if (exists e = sie.expression,
                exists term = e.term,
                node == term) {
                parameter = that.declarationModel;
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.InitializerParameter that) {
        if (exists se = that.specifierExpression) {
            if (exists e = se.expression,
                exists term = e.term,
                node == term) {
                parameter = that.parameterModel.model;
            }
        }
        super.visit(that);
    }
    
    shared actual void visit(Tree.InvocationExpression that) {
        value oc = current;
        current = that;
        super.visit(that);
        current = oc;
    }
    
    shared actual void visit(Tree.BaseMemberExpression that) {
        if (that == node) {
            result = current;
        }
        super.visit(that);
    }
}
