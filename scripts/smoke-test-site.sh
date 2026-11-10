#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-https://wenhan.blog}"
response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

check_page() {
  local path="$1"
  local marker="$2"
  local url="${base_url%/}${path}"
  local status=""

  echo "Checking ${url}"
  if ! status="$(curl --location --silent --show-error --fail \
    --retry 8 --retry-all-errors --retry-delay 10 --retry-max-time 180 \
    --max-time 20 --output "$response_file" --write-out '%{http_code}' "$url")"; then
    echo "ERROR: request failed for ${url}" >&2
    return 1
  fi

  if [[ "$status" != "200" ]]; then
    echo "ERROR: ${url} returned HTTP ${status}" >&2
    return 1
  fi

  if [[ -n "$marker" ]] && ! grep --fixed-strings --quiet -- "$marker" "$response_file"; then
    echo "ERROR: expected content '${marker}' was not found at ${url}" >&2
    return 1
  fi

  echo "OK: ${url} returned HTTP ${status}"
}

check_sitemap() {
  local url="${base_url%/}/sitemap.xml"
  local status=""

  echo "Checking ${url}"
  if ! status="$(curl --location --silent --show-error --fail \
    --retry 8 --retry-all-errors --retry-delay 10 --retry-max-time 180 \
    --max-time 20 --output "$response_file" --write-out '%{http_code}' "$url")"; then
    echo "ERROR: request failed for ${url}" >&2
    return 1
  fi

  if [[ "$status" != "200" ]] || ! grep --extended-regexp --quiet '<(urlset|sitemapindex)([[:space:]>])' "$response_file"; then
    echo "ERROR: ${url} did not return a valid sitemap (HTTP ${status})" >&2
    return 1
  fi

  echo "OK: ${url} returned a sitemap (HTTP ${status})"
}

check_page "/" "Wenhan blog"
check_page "/posts/" "SonarQube"
check_page "/en/" "Wenhan blog"
check_page "/zh/" "Wenhan blog"
check_sitemap
