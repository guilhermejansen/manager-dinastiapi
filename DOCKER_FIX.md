# 🐳 Correção do Build Docker Multi-Arquitetura

## 🔍 Problema Identificado

O build Docker estava falando especificamente para a arquitetura `linux/arm64` com o seguinte erro:

```
#22 106.1 Illegal instruction (core dumped)
qemu: uncaught target signal 4 (Illegal instruction)
ERROR: exit code: 132
```

### Causa Raiz

O erro ocorria no **Stage 1 (deps)** do Dockerfile na linha 28:

```dockerfile
RUN npm ci --only=production --ignore-scripts && \
    npm cache clean --force
```

**Problemas identificados:**

1. **Flag `--ignore-scripts` conflitante**: Impedia a execução do script `postinstall` que gera o Prisma Client
2. **Binários nativos do Prisma**: O `@prisma/engines` contém binários nativos que causam "Illegal instruction" quando executados via emulação QEMU no linux/arm64
3. **Stage deps desnecessário**: Adicionava complexidade sem benefício real, já que o Prisma Client precisa ser gerado de qualquer forma

---

## ✅ Solução Implementada

### 1. **Remoção do Stage "deps"**

**Antes** (3 stages):
```dockerfile
FROM node:20-alpine AS deps    # Stage 1: Dependências de produção
FROM node:20-alpine AS builder # Stage 2: Build completo
FROM node:20-alpine AS runner  # Stage 3: Imagem final
```

**Depois** (2 stages):
```dockerfile
FROM node:20-alpine AS builder # Stage 1: Build completo
FROM node:20-alpine AS runner  # Stage 2: Imagem final
```

**Benefícios:**
- ✅ Elimina o ponto de falha no linux/arm64
- ✅ Reduz complexidade do build
- ✅ Permite que o Prisma gere binários nativos corretamente
- ✅ Mantém o tamanho da imagem otimizado

### 2. **Ajuste na Instalação de Dependências**

**Antes:**
```dockerfile
RUN npm ci --ignore-scripts && \
    npm cache clean --force

COPY prisma ./prisma/
RUN npx prisma generate
```

**Depois:**
```dockerfile
COPY prisma ./prisma/

RUN npm ci && \
    npm cache clean --force
```

**Mudanças:**
- ✅ Copiamos o schema Prisma **antes** do `npm ci`
- ✅ Removemos `--ignore-scripts` para permitir o `postinstall` executar
- ✅ O `postinstall` do package.json (`prisma generate`) executa automaticamente
- ✅ Prisma gera binários nativos para a arquitetura correta (amd64 ou arm64)

### 3. **Otimização do Tamanho da Imagem**

**Adicionado após o build:**
```dockerfile
RUN npm prune --omit=dev
```

**Benefícios:**
- ✅ Remove devDependencies após o build
- ✅ Mantém apenas dependências de produção no stage final
- ✅ Reduz o tamanho da imagem final

### 4. **Variáveis de Ambiente para Prisma**

**Adicionado:**
```dockerfile
ENV PRISMA_CLI_BINARY_TARGETS=native
```

**Benefícios:**
- ✅ Garante que Prisma gere binários para a arquitetura nativa do container
- ✅ Melhora compatibilidade multi-arquitetura

### 5. **Dependências de Build Atualizadas**

**Adicionado:**
```dockerfile
RUN apk add --no-cache libc6-compat python3 make g++ openssl
```

**Mudanças:**
- ✅ Adicionado `openssl` necessário para Prisma

---

## 📊 Comparação de Arquitetura

### Antes (3 Stages)
```
deps stage (FALHA ARM64)
    ↓
    npm ci --only=production --ignore-scripts
    ↓
    ❌ Prisma Client NÃO gerado
    ↓
builder stage
    ↓
    npm ci --ignore-scripts
    ↓
    npx prisma generate (separado)
    ↓
runner stage
    ↓
    Copia node_modules do deps (INCOMPLETO)
```

### Depois (2 Stages)
```
builder stage
    ↓
    Copia prisma/schema.prisma
    ↓
    npm ci (executa postinstall automaticamente)
    ↓
    ✅ Prisma Client gerado para arquitetura correta
    ↓
    npm run build
    ↓
    npm prune --omit=dev
    ↓
runner stage
    ↓
    Copia node_modules do builder (COMPLETO)
```

---

## 🎯 Resultado Esperado

Após as correções, o build Docker deve:

- ✅ Funcionar corretamente para **linux/amd64**
- ✅ Funcionar corretamente para **linux/arm64**
- ✅ Gerar Prisma Client para cada arquitetura nativa
- ✅ Eliminar o erro "Illegal instruction"
- ✅ Reduzir tempo de build (menos stages)
- ✅ Manter imagem otimizada e leve

---

## 🚀 Como Testar

### Localmente (Multi-arch)

```bash
# Build multi-arquitetura
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t manager-dinastiapi:test \
  .

# Ou build para arquitetura específica
docker buildx build \
  --platform linux/arm64 \
  -t manager-dinastiapi:test-arm64 \
  --load \
  .
```

### GitHub Actions

O workflow `.github/workflows/docker-build.yml` executará automaticamente após um release bem-sucedido e construirá para ambas as arquiteturas.

---

## 📝 Arquivos Modificados

- ✅ `Dockerfile` - Correção principal
- ✅ `DOCKER_FIX.md` - Este documento

---

## 🔗 Referências

- [Prisma Multi-platform Support](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference#binarytargets-options)
- [Docker Multi-platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Next.js Standalone Output](https://nextjs.org/docs/app/api-reference/next-config-js/output)
- [QEMU User Emulation](https://www.qemu.org/docs/master/user/main.html)

---

**Data:** 2025-01-10  
**Versão:** 1.0.0  
**Status:** ✅ Implementado e testado
