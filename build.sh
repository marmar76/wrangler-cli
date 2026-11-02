docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t marmar76/wrangler-cli:latest \
  .