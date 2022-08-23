#! /bin/bash
curl -s -H 'Accept: application/vnd.github+json' https://api.github.com/repos/endaft/aws-cloudfront-gateway/contents/dist | jq '.[0] | { sha: .sha }'