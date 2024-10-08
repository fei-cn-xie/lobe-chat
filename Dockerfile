## Base image for all the stages
FROM node:20-alpine AS base

RUN \
    # Add user nextjs to run the app
    addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

## Builder image, install all the dependencies and build the app
FROM base AS builder

ARG USE_NPM_CN_MIRROR

ENV NEXT_PUBLIC_BASE_PATH=""

# Sentry
ENV NEXT_PUBLIC_SENTRY_DSN="" \
    SENTRY_ORG="" \
    SENTRY_PROJECT=""

    
# Posthog
ENV NEXT_PUBLIC_ANALYTICS_POSTHOG="" \
    NEXT_PUBLIC_POSTHOG_HOST="" \
    NEXT_PUBLIC_POSTHOG_KEY=""

# Umami
ENV NEXT_PUBLIC_ANALYTICS_UMAMI="" \
    NEXT_PUBLIC_UMAMI_SCRIPT_URL="" \
    NEXT_PUBLIC_UMAMI_WEBSITE_ID=""

# Node
ENV NODE_OPTIONS="--max-old-space-size=8192"

WORKDIR /app

COPY package.json ./
COPY .npmrc ./

RUN \
    # If you want to build docker in China, build with --build-arg USE_NPM_CN_MIRROR=true
    if [ "${USE_NPM_CN_MIRROR:-false}" = "true" ]; then \
        export SENTRYCLI_CDNURL="https://npmmirror.com/mirrors/sentry-cli"; \
        npm config set registry "https://registry.npmmirror.com/"; \
    fi \
    # Set the registry for corepack
    && export COREPACK_NPM_REGISTRY=$(npm config get registry | sed 's/\/$//') \
    # Enable corepack
    && corepack enable \
    # Use pnpm for corepack
    && corepack use pnpm \
    # Install the dependencies
    && pnpm i \
    # Add sharp dependencies
    && mkdir -p /sharp \
    && pnpm add sharp --prefix /sharp

COPY . .

# run build standalone for docker version
RUN npm run build:docker

## Application image, copy all the files for production
FROM scratch AS appxx

COPY --from=builder /app/public /app/public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder /app/.next/standalone /app/
COPY --from=builder /app/.next/static /app/.next/static
COPY --from=builder /sharp/node_modules/.pnpm /app/node_modules/.pnpm

## Production image, copy all the files and run next
FROM base

# Copy all the files from app, set the correct permission for prerender cache
COPY --from=app --chown=nextjs:nodejs /app /app

ENV NODE_ENV="production"

# set hostname to localhost
ENV HOSTNAME="0.0.0.0" \
    PORT="3210"

# General Variables
ENV ACCESS_CODE="" \
    API_KEY_SELECT_MODE="" \
    FEATURE_FLAGS=""

# Model Variables
ENV \
    # Ai360
    AI360_API_KEY="" \
    # Anthropic
    ANTHROPIC_API_KEY="" ANTHROPIC_PROXY_URL="" \
    # Amazon Bedrock
    AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" AWS_REGION="" \
    # Azure OpenAI
    AZURE_API_KEY="" AZURE_API_VERSION="" AZURE_ENDPOINT="" AZURE_MODEL_LIST="" \
    # Baichuan
    BAICHUAN_API_KEY="" \
    # DeepSeek
    DEEPSEEK_API_KEY="" \
    # Google
    GOOGLE_API_KEY="" GOOGLE_PROXY_URL="" \
    # Groq
    GROQ_API_KEY="" GROQ_PROXY_URL="" \
    # Minimax
    MINIMAX_API_KEY="" \
    # Mistral
    MISTRAL_API_KEY="" \
    # Moonshot
    MOONSHOT_API_KEY="" MOONSHOT_PROXY_URL="" \
    # Novita
    NOVITA_API_KEY="" \
    # Ollama
    OLLAMA_MODEL_LIST="" OLLAMA_PROXY_URL="" \
    # OpenAI
    OPENAI_API_KEY="" OPENAI_MODEL_LIST="" OPENAI_PROXY_URL="" \
    # OpenRouter
    OPENROUTER_API_KEY="" OPENROUTER_MODEL_LIST="" \
    # Perplexity
    PERPLEXITY_API_KEY="" PERPLEXITY_PROXY_URL="" \
    # Qwen
    QWEN_API_KEY="" \
    # Stepfun
    STEPFUN_API_KEY="" \
    # Taichu
    TAICHU_API_KEY="" \
    # TogetherAI
    TOGETHERAI_API_KEY="" TOGETHERAI_MODEL_LIST="" \
    # 01.AI
    ZEROONE_API_KEY="" \
    # Zhipu
    ZHIPU_API_KEY=""

USER nextjs

EXPOSE 3210/tcp

CMD ["node", "/app/server.js"]
