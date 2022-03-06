import "math" for M
class Log {
  construct new() {
    _content = []
  }

  content { _content }
  add(text) {
    content.add(text)
  }
  getLast(n) {
    return content.skip(M.max(0, content.count - n)).take(n).toList
  }
}
