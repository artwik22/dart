import urllib.request
import sys
import base64
import os

html = f"""
<!DOCTYPE html>
<html>
<head><title>Searching...</title></head>
<body onload="document.getElementById('f').submit()">
<form id="f" method="POST" action="https://lens.google.com/v3/upload" enctype="multipart/form-data">
<input type="hidden" name="encoded_image" value="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVQI12NgAAIAAAUAAeIm1fQAAAAASUVORK5CYII=">
</form>
</body>
</html>
"""
with open('/tmp/lens_search.html', 'w') as f:
    f.write(html)
print("Generated html")
