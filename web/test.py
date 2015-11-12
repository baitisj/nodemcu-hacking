import cgi

def application(env, start_response):
  start_response('200 OK', [('Content-Type','text/html')])
  form = cgi.FieldStorage(environ=env)
  html = "OK\n"
  if 'data' in form:
      html += "You said: {}\n".format(form['data'].value)
  return html
