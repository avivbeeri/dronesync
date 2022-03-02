import "meta" for Meta
import "io" for FileSystem

var files = FileSystem.listFiles("./views")
var path = FileSystem.basePath()
for (file in files) {
  var index = file.indexOf(".wren")
  if (index == -1) {
    continue
  }
  var moduleName = file[0...index]
  var source = "import \"./views/%(moduleName)\""
  Meta.eval(source)
  var variables = Meta.getModuleVariables("views/%(moduleName)")
  for (variable in variables) {
    var source = "import \"./views/%(moduleName)\" for %(variable)\n"
    var out = Fiber.new {
      var obj = Meta.eval(source)  //> 6
    }.try()
    if (!out) {
      System.print(variable)
      Fiber.new {
      System.print(Meta.compileExpression("%(variable).attributes.self").call())
      }.try()
    }
  }
}

/*
var source = """
  import "./views/animations" for SleepAnimation
  import "./views/renderer" for WorldRenderer
  import "./views/statusbar" for StatusBar
  import "./views/tooltip" for Tooltip
"""

Meta.eval(source)  //> 6

*/
