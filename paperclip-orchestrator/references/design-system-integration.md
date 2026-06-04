# Layer 4: Design System Integration

## What is DESIGN.md?

A plain-text Markdown design system document from [awesome-design-md](https://github.com/VoltAgent/awesome-design-md) — a curated collection of 58+ real-world brand design specifications. Each DESIGN.md contains 9 modules defining a brand's complete visual language.

## How L3 and L4 Work Together

| Layer | Tool | Role | Question Answered |
|-------|------|------|-------------------|
| L3 | taste-skill | Anti-slop engine | "Is it NOT generic AI slop?" |
| L4 | DESIGN.md | Brand DNA spec | "Does it look like Vercel?" |

**L3 without L4**: Beautiful, non-generic UI — but might not match any specific brand.
**L4 without L3**: Matches the brand tokens — but might still feel "AI-generated".
**L3 + L4**: Premium, production-grade UI that matches a target brand AND feels hand-crafted.

## Brand Selection Guide

### By Use Case

| Use Case | Recommended Brands |
|----------|-------------------|
| Developer SaaS (dark) | vercel, linear, supabase |
| Developer SaaS (light) | notion, github |
| Fintech/Crypto | stripe, revolut, coinbase |
| AI/ML Product | claude, perplexity, chatgpt |
| Consumer App | apple, spotify, airbnb |
| Enterprise Dashboard | cloudflare, mongodb, aws |
| Bold/Brand-heavy | tesla, nike, spacex |
| Minimal/Editorial | notion, linear, shadcn |

### By Vibe

| Vibe | Brands |
|------|--------|
| Dark + Geometric | vercel, linear |
| Dark + Warm | claude, stripe |
| Dark + Bold | tesla, spacex, nike |
| Dark + Developer | github, supabase, tailwind |
| Light + Premium | apple, airbnb |
| Light + Editorial | notion |
| Dark + Fintech | revolut, robinhood |

## Workflow

### 1. Discover (Architect)
```bash
paperclip-design-fetcher agent search "dark saas developer"
paperclip-design-fetcher agent recommend "minimal fintech dashboard"
```

### 2. Select & Fetch (Architect)
```bash
paperclip-design-fetcher agent fetch vercel --output ./my-project
# → creates .paperclip/design/DESIGN.md
# → creates .paperclip/design/brand.json (metadata)
```

### 3. Review & Document (Architect)
Read DESIGN.md → extract key tokens → document in project spec:
- Color tokens (--primary, --surface, --accent, etc.)
- Font stack + type scale
- Spacing scale
- Border radius, shadow levels

### 4. Implement (Developer)
```
1. Read .paperclip/design/DESIGN.md
2. Map brand tokens to CSS custom properties
3. Use taste-skill for anti-slop execution (DESIGN_VARIANCE=5)
4. Every color/font/spacing decision references DESIGN.md
```

### 5. Review (Reviewer)
```
1. Check color token usage vs DESIGN.md
2. Check typography scale vs TYPE_SCALE
3. Check component styles vs COMPONENT_STYLINGS
4. Flag any deviation as P1 (should fix)
```

## Custom DESIGN.md

Create your own brand spec using the template:
```markdown
# My Brand Design System

## Visual Theme & Atmosphere
[Describe mood, density, philosophy]

## Color Palette & Roles
| Token | Hex | Role |
|-------|-----|------|
| --primary | #... | Primary brand color |

## Typography Rules
[Font families, type scale table]

## Component Stylings
[Buttons, inputs, cards, nav — with states]

## Layout Principles
[Grid, spacing scale, whitespace]

## Depth & Elevation
[Shadow system, surface layers]

## Do's and Don'ts
[Design constraints and anti-patterns]

## Responsive Behavior
[Breakpoints, touch targets]
```

## Commands Reference

```bash
# List all brands
paperclip-design-fetcher agent list

# Filter by category
paperclip-design-fetcher agent list --category "Developer Tools"

# Search by vibe/keywords
paperclip-design-fetcher agent search "dark fintech minimal"

# AI-powered recommendation
paperclip-design-fetcher agent recommend "modern saas dashboard with dark mode"

# Fetch a brand
paperclip-design-fetcher agent fetch vercel

# Compare multiple brands
paperclip-design-fetcher agent fetch vercel stripe linear --output ./designs

# Init with design
python scripts/init_company.py --name my-app --design vercel
```
