import kagamine, rin from require "rin"
import await, hatsune, miku from require "hatsune"

scheduler = hatsune!

url = "https://example.com"

prettyPrintResponse = (response) ->
  body = response\text!
  statusText = if response.statusText
    " (#{response.statusText})"
  else
    ""
  print "#{url} responded with status code #{response.status}#{statusText}, body:\n#{body}"

scheduler\run ->
  response = await rin url
  prettyPrintResponse response
