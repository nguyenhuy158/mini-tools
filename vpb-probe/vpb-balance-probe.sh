#!/bin/sh
set -eu
umask 077

TOKEN_URL="${TOKEN_URL:-https://openapi.vpbank.com.vn/security/token}"
PRODUCTS_URL="${PRODUCTS_URL:-https://openapi.vpbank.com.vn/corporate/customer/v1/customer/products}"
PRODUCT_TYPES="${PRODUCT_TYPES:-CA}"

missing=""
for name in VPBANK_CONSUMER_KEY VPBANK_SECRET_KEY IDN_APP CIF; do
  eval "value=\${$name:-}"
  [ -n "$value" ] || missing="$missing $name"
done
if [ -n "$missing" ]; then
  echo "missing env:$missing"
  exit 2
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

error_body_flag=""
if wget --help 2>&1 | grep -q 'content-on-error'; then
  error_body_flag="--content-on-error"
fi

status_of() {
  code="$(grep -o 'HTTP/[0-9.]* [0-9][0-9][0-9]' "$1" | tail -1 | awk '{print $2}')"
  if [ -z "$code" ]; then
    code="$(grep -o 'error: HTTP/[0-9.]* [0-9][0-9][0-9]' "$1" | tail -1 | awk '{print $3}')"
  fi
  echo "${code:-200}"
}

basic="$(printf '%s:%s' "$VPBANK_CONSUMER_KEY" "$VPBANK_SECRET_KEY" | base64 | tr -d '\n')"

echo "token url: $TOKEN_URL"
token_rc=0
wget -S -q $error_body_flag -O "$work/token.json" \
  --header "Authorization: Basic $basic" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --header "IDN-App: $IDN_APP" \
  --post-data "grant_type=client_credentials" \
  "$TOKEN_URL" 2>"$work/token.err" || token_rc=$?
token_status="$(status_of "$work/token.err")"
echo "token status: $token_status (wget rc=$token_rc)"
if [ "$token_rc" -ne 0 ]; then
  echo "token error body (first 300 chars):"
  head -c 300 "$work/token.json" 2>/dev/null || true
  echo
  exit 3
fi

access_token="$(grep -o '"access_token" *: *"[^"]*"' "$work/token.json" | awk -F'"' '{print $4}')"
token_type="$(grep -o '"token_type" *: *"[^"]*"' "$work/token.json" | awk -F'"' '{print $4}')"
if [ -z "$access_token" ]; then
  echo "token response has no access_token"
  exit 3
fi

echo "products url: $PRODUCTS_URL"
request_id="probe-$(date +%s)"
body="{\"cif\":\"$CIF\",\"productTypes\":\"$PRODUCT_TYPES\"}"
products_rc=0
wget -S -q $error_body_flag -O "$work/products.json" \
  --header "Authorization: ${token_type:-Bearer} $access_token" \
  --header "IDN-App: $IDN_APP" \
  --header "x-request-id: $request_id" \
  --header "Content-Type: application/json" \
  --post-data "$body" \
  "$PRODUCTS_URL" 2>"$work/products.err" || products_rc=$?
products_status="$(status_of "$work/products.err")"
echo "products status: $products_status (wget rc=$products_rc)"

if [ "$products_rc" -ne 0 ]; then
  echo "error body (first 300 chars):"
  head -c 300 "$work/products.json" 2>/dev/null || true
  echo
  exit 4
fi

echo "ca accounts returned:"
grep -o '"accountNumber" *: *"[0-9]*"' "$work/products.json" | awk -F'"' '{n=$4; print "  ***" substr(n, length(n)-3)}'
echo "currencies:"
grep -o '"accountCurrency" *: *"[A-Z]*"' "$work/products.json" | awk -F'"' '{print "  " $4}' | sort | uniq -c
echo "balanceInfo blocks: $(grep -o '"balanceInfo"' "$work/products.json" | wc -l | tr -d ' ')"
