#!/usr/bin/env bash
# cloudinary-debug.sh — Debug Cloudinary credentials and API connection

source "$HOME/espanso-utility/shared.sh"

echo "cloud: $CLOUDINARY_CLOUD_NAME"
echo "key:   $CLOUDINARY_API_KEY"
echo "secret len: ${#CLOUDINARY_API_SECRET}"

sha1_hex() {
  echo -n "$1" | openssl sha1 | awk '{print $2}'
}

timestamp=$(date +%s)
sig_string="max_results=10&timestamp=${timestamp}${CLOUDINARY_API_SECRET}"
echo "sigString: $sig_string"

signature=$(sha1_hex "$sig_string")
echo "signature: $signature"

url="https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/resources/image?max_results=10&timestamp=${timestamp}&api_key=${CLOUDINARY_API_KEY}&signature=${signature}"
echo "url: $url"

response=$(curl -s "$url")
echo "RAW: $response"
