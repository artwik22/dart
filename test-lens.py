import urllib.request
import urllib.parse
import uuid
import sys
import re

try:
    with open('/tmp/lens_test.png', 'rb') as f:
        image_data = f.read()
except:
    sys.exit(1)

boundary = uuid.uuid4().hex
body = bytearray()
body.extend(f'--{boundary}\r\n'.encode('utf-8'))
body.extend(b'Content-Disposition: form-data; name=\"encoded_image\"; filename=\"image.png\"\r\n')
body.extend(b'Content-Type: image/png\r\n\r\n')
body.extend(image_data)
body.extend(f'\r\n--{boundary}--\r\n'.encode('utf-8'))

headers = {
    'Content-Type': f'multipart/form-data; boundary={boundary}',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

req = urllib.request.Request('https://lens.google.com/v3/upload', data=body, headers=headers)
try:
    response = urllib.request.urlopen(req)
    html = response.read().decode('utf-8', errors='ignore')
    match = re.search(r'URL=([^"]+)', html)
    if match:
        print("REDIRECT:", match.group(1))
    else:
        print("NO REDIRECT FOUND IN HTML")
        print(html[:500])
except Exception as e:
    print('ERROR:', str(e))
