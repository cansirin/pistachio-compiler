coffee = require 'coffee-script'

pistachios =
  ///
  \{                    # first { (begins symbol)
    ((?:[\w|-]*)?       # optional custom html tag name
    (?:\#[\w|-]*)?      # optional id - #-prefixed
    (?:(?:\.[\w|-]*)*)  # optional class names - .-prefixed
    (?:\[               # optional [ begins the attributes
      (?:\b[\w|-]*\b)   # the name of the attribute
      (?:\=             # optional assignment operator =
                        # TODO: this will tolerate fuzzy quotes for now. "e.g.'
        [\"|\']?        # optional quotes
        .*              # optional value
        [\"|\']?        # optional quotes
      )
    \])*)               # optional ] closes the attribute tag(s). there can be many attributes.
    \{                  # second { (begins expression)
      ([^{}]*)          # practically anything can go between the braces, except {}
    \}\s*               # closing } (ends expression)
  \}                    # closing } (ends symbol)
  ///g

literalId = 0

module.exports =(literal)->
  unless 'string' is typeof literal
    return literal
  else
    dataExprs = {}
    dataExprCount = 0
    compiledExpr = literal.replace pistachios, (_, markup, expr)->
      embedView = no
      if /^> ?/.test expr
        expr = expr.substr(1).trim()
        embedView = yes
      preparedExpr = expr.replace /#\((?:[^)]*)\)/g, (dataExpr)->
        dataExprId = "__expr-#{literalId}-#{dataExprCount}"
        dataExprs[dataExprId] = dataExpr
        dataExprCount++
        return "'#{dataExprId}'"
      compiledExpr =\
        try coffee.compile(preparedExpr.replace(/\\"/g, "\""), bare: yes).replace(/"/g,'\\"')
        catch e then console.error e; preparedExpr
      if compiledExpr.match(/;/g)?.length > 1
        throw new SyntaxError 'Only one expression is allowed.'
      else compiledExpr = compiledExpr.replace(/\n|;/g, '')
      processedExpr = compiledExpr
        .replace /\'(__expr-[0-9]+-[0-9]+)\'/g, (_, placeholder)->
          return dataExprs[placeholder]
      return "{#{markup}{#{if embedView then '> ' else ''}#{processedExpr}}}"
    literalId++
    return compiledExpr