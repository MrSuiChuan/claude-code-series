#!/usr/bin/env python3
"""
PaperClip Design Fetcher (Layer 4)
===================================
Fetch DESIGN.md files from awesome-design-md on demand.
Provides list, search, fetch, and preview commands.

Usage:
    python design_fetcher.py list [--category <name>]
    python design_fetcher.py search <query>
    python design_fetcher.py fetch <brand> [--output <dir>]
    python design_fetcher.py fetch <brand1> <brand2> ... --output <dir>
    python design_fetcher.py recommend "dark mode fintech dashboard"
"""

import os
import sys
import json
import argparse
import urllib.request
import urllib.error
from pathlib import Path

# ============================================================
# Brand Index — all 58+ brands from awesome-design-md
# ============================================================
# Categories and keywords for search/discovery
BRANDS = {
    # ---- AI & Machine Learning ----
    "claude": {
        "name": "Claude (Anthropic)",
        "category": "AI & Machine Learning",
        "keywords": ["ai", "dark", "minimal", "chat", "assistant"],
        "vibe": "warm minimal dark, paper-like textures, amber accents",
    },
    "chatgpt": {
        "name": "ChatGPT (OpenAI)",
        "category": "AI & Machine Learning",
        "keywords": ["ai", "chat", "minimal", "green", "clean"],
        "vibe": "clean minimal, signature green, spacious layout",
    },
    "perplexity": {
        "name": "Perplexity AI",
        "category": "AI & Machine Learning",
        "keywords": ["ai", "search", "dark", "academic", "minimal"],
        "vibe": "scholarly dark, serif typography, muted palette",
    },
    "midjourney": {
        "name": "Midjourney",
        "category": "AI & Machine Learning",
        "keywords": ["ai", "creative", "dark", "image", "art"],
        "vibe": "art-gallery dark, minimal chrome, image-forward",
    },

    # ---- Developer Tools & Platforms ----
    "vercel": {
        "name": "Vercel",
        "category": "Developer Tools",
        "keywords": ["dark", "developer", "geometric", "platform", "saas"],
        "vibe": "geometric dark, precise grid, accent glows, monospace",
    },
    "linear": {
        "name": "Linear",
        "category": "Developer Tools",
        "keywords": ["dark", "minimal", "productivity", "precision", "keyboard"],
        "vibe": "ultra-precise dark, keyboard-first, subtle gradients",
    },
    "github": {
        "name": "GitHub",
        "category": "Developer Tools",
        "keywords": ["dark", "developer", "code", "platform", "blue"],
        "vibe": "developer-native dark, blue accents, dense information",
    },
    "stripe": {
        "name": "Stripe",
        "category": "Developer Tools",
        "keywords": ["dark", "fintech", "developer", "api", "gradient"],
        "vibe": "polished dark, gradient backgrounds, blue-purple accents",
    },
    "notion": {
        "name": "Notion",
        "category": "Developer Tools",
        "keywords": ["light", "minimal", "productivity", "editorial", "clean"],
        "vibe": "editorial minimal, serif + sans mix, generous whitespace",
    },
    "tailwind": {
        "name": "Tailwind CSS",
        "category": "Developer Tools",
        "keywords": ["dark", "developer", "css", "utility", "blue"],
        "vibe": "utility-first dark, sky blue, clean typography",
    },
    "shadcn": {
        "name": "shadcn/ui",
        "category": "Developer Tools",
        "keywords": ["dark", "component", "react", "minimal", "neutral"],
        "vibe": "component-driven dark, neutral palette, clean borders",
    },
    "figma": {
        "name": "Figma",
        "category": "Developer Tools",
        "keywords": ["dark", "design", "tool", "creative", "purple"],
        "vibe": "design-tool dark, purple accents, canvas metaphor",
    },
    "supabase": {
        "name": "Supabase",
        "category": "Developer Tools",
        "keywords": ["dark", "developer", "database", "green", "backend"],
        "vibe": "developer dark, signature green, terminal aesthetic",
    },

    # ---- Design & Productivity ----
    "apple": {
        "name": "Apple",
        "category": "Design & Productivity",
        "keywords": ["light", "minimal", "premium", "clean", "consumer"],
        "vibe": "premium minimal, San Francisco fonts, frosted glass",
    },
    "spotify": {
        "name": "Spotify",
        "category": "Design & Productivity",
        "keywords": ["dark", "music", "consumer", "green", "bold"],
        "vibe": "music-first dark, signature green, bold typography",
    },
    "airbnb": {
        "name": "Airbnb",
        "category": "Design & Productivity",
        "keywords": ["light", "warm", "consumer", "photography", "travel"],
        "vibe": "warm minimal, photography-forward, rounded everything",
    },

    # ---- Fintech & Crypto ----
    "revolut": {
        "name": "Revolut",
        "category": "Fintech & Crypto",
        "keywords": ["dark", "fintech", "banking", "premium", "black"],
        "vibe": "premium dark fintech, semantic tokens, sharp precision",
    },
    "robinhood": {
        "name": "Robinhood",
        "category": "Fintech & Crypto",
        "keywords": ["dark", "fintech", "trading", "green", "consumer"],
        "vibe": "consumer trading dark, signature green, gamified",
    },
    "coinbase": {
        "name": "Coinbase",
        "category": "Fintech & Crypto",
        "keywords": ["dark", "crypto", "blue", "trust", "platform"],
        "vibe": "institutional crypto dark, trust blue, clean data",
    },
    "wise": {
        "name": "Wise (TransferWise)",
        "category": "Fintech & Crypto",
        "keywords": ["light", "fintech", "green", "clean", "trust"],
        "vibe": "clean fintech, signature green, friendly rounded",
    },

    # ---- Enterprise & Consumer ----
    "tesla": {
        "name": "Tesla",
        "category": "Enterprise & Consumer",
        "keywords": ["dark", "premium", "automotive", "bold", "cinematic"],
        "vibe": "cinematic dark, full-bleed imagery, bold minimal",
    },
    "nike": {
        "name": "Nike",
        "category": "Enterprise & Consumer",
        "keywords": ["dark", "bold", "sports", "consumer", "black"],
        "vibe": "athletic bold dark, impactful typography, high contrast",
    },
    "mongodb": {
        "name": "MongoDB",
        "category": "Infrastructure & Cloud",
        "keywords": ["dark", "developer", "database", "green", "terminal"],
        "vibe": "deep-forest-meets-terminal, signature green, code-first",
    },
    "cloudflare": {
        "name": "Cloudflare",
        "category": "Infrastructure & Cloud",
        "keywords": ["dark", "infrastructure", "orange", "developer", "security"],
        "vibe": "infrastructure dark, signature orange, technical clarity",
    },
    "aws": {
        "name": "Amazon Web Services",
        "category": "Infrastructure & Cloud",
        "keywords": ["dark", "cloud", "enterprise", "orange", "dense"],
        "vibe": "enterprise cloud dark, signature orange, dense data",
    },
    "spacex": {
        "name": "SpaceX",
        "category": "Enterprise & Consumer",
        "keywords": ["dark", "bold", "space", "cinematic", "uppercase"],
        "vibe": "cinematic maximalist dark, uppercase, dramatic scale",
    },
}

GITHUB_RAW = "https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main"
CACHE_DIR = Path.home() / ".paperclip" / "design-cache"


def _brand_key(name):
    """Normalize brand name to lowercase key."""
    return name.lower().replace(" ", "-")


def _brand_exists(key):
    """Check if brand key exists in index."""
    return key in BRANDS


def list_brands(category=None):
    """List available brands, optionally filtered by category."""
    results = []
    for key, info in BRANDS.items():
        if category and info["category"].lower() != category.lower():
            continue
        results.append((key, info))

    return sorted(results, key=lambda x: x[1]["name"])


def search_brands(query):
    """Search brands by keyword match in name, category, keywords, and vibe."""
    query_lower = query.lower()
    terms = query_lower.split()
    scored = []

    for key, info in BRANDS.items():
        score = 0
        search_text = (
            info["name"].lower() + " " +
            info["category"].lower() + " " +
            " ".join(info["keywords"]) + " " +
            info["vibe"].lower()
        )
        for term in terms:
            if term in info["name"].lower():
                score += 10
            if term in info["category"].lower():
                score += 5
            if term in " ".join(info["keywords"]):
                score += 3
            if term in info["vibe"].lower():
                score += 2
            if term in search_text:
                score += 1

        if score > 0:
            scored.append((score, key, info))

    scored.sort(key=lambda x: x[0], reverse=True)
    return [(key, info, score) for score, key, info in scored]


def recommend_brands(query, top_n=5):
    """Recommend brands based on a natural language query."""
    results = search_brands(query)
    return results[:top_n]


def _cache_valid(brand_key):
    """Check if cached DESIGN.md is still fresh (< 24 hours)."""
    import time
    cache_file = CACHE_DIR / f"{brand_key}.md"
    if not cache_file.exists():
        return False
    age = time.time() - cache_file.stat().st_mtime
    return age < 86400  # 24 hours


def _read_cache(brand_key):
    """Read DESIGN.md from local cache."""
    cache_file = CACHE_DIR / f"{brand_key}.md"
    if cache_file.exists():
        return cache_file.read_text(encoding="utf-8")
    return None


def _write_cache(brand_key, content):
    """Write DESIGN.md to local cache."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    (CACHE_DIR / f"{brand_key}.md").write_text(content, encoding="utf-8")


def fetch_brand(brand_key, output_dir):
    """Fetch DESIGN.md and preview files for a brand from GitHub (with local cache)."""
    if not _brand_exists(brand_key):
        print(f'{{"error": "Unknown brand: {brand_key}. Use list/search to find brands."}}')
        return None

    info = BRANDS[brand_key]
    output_path = Path(output_dir) / ".paperclip" / "design"
    output_path.mkdir(parents=True, exist_ok=True)

    fetched = []

    # Fetch DESIGN.md — use cache if fresh
    design_url = f"{GITHUB_RAW}/design-md/{brand_key}/DESIGN.md"

    if _cache_valid(brand_key):
        content = _read_cache(brand_key)
        design_path = output_path / "DESIGN.md"
        with open(design_path, "w", encoding="utf-8") as f:
            f.write(content)
        fetched.append(str(design_path))
    else:
        try:
            with urllib.request.urlopen(design_url) as resp:
                content = resp.read().decode("utf-8")
                _write_cache(brand_key, content)
                design_path = output_path / "DESIGN.md"
                with open(design_path, "w", encoding="utf-8") as f:
                    f.write(content)
                fetched.append(str(design_path))
        except urllib.error.HTTPError as e:
            # Fall back to stale cache if available
            cached = _read_cache(brand_key)
            if cached:
                design_path = output_path / "DESIGN.md"
                with open(design_path, "w", encoding="utf-8") as f:
                    f.write(cached)
                fetched.append(str(design_path))
                print(f'{{"warning": "Using cached DESIGN.md for {brand_key} (HTTP {e.code})"}}')
            else:
                print(f'{{"warning": "DESIGN.md not found for {brand_key} (HTTP {e.code})"}}')

    # Fetch preview files
    for preview_file in ["preview.html", "preview-dark.html"]:
        preview_url = f"{GITHUB_RAW}/design-md/{brand_key}/{preview_file}"
        try:
            with urllib.request.urlopen(preview_url) as resp:
                content = resp.read().decode("utf-8")
                preview_path = output_path / preview_file
                with open(preview_path, "w", encoding="utf-8") as f:
                    f.write(content)
                fetched.append(str(preview_path))
        except urllib.error.HTTPError:
            pass  # preview files are optional

    # Save brand metadata
    meta = {
        "brand": brand_key,
        "name": info["name"],
        "category": info["category"],
        "vibe": info["vibe"],
        "fetched_at": __import__("datetime").datetime.now().isoformat(),
    }
    with open(output_path / "brand.json", "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)

    return {
        "brand": brand_key,
        "name": info["name"],
        "category": info["category"],
        "vibe": info["vibe"],
        "files": fetched,
        "output": str(output_path),
    }


def fetch_multiple(brand_keys, output_base):
    """Fetch multiple brands for comparison."""
    results = {}
    for key in brand_keys:
        brand_dir = Path(output_base) / key
        result = fetch_brand(key, str(brand_dir))
        if result:
            results[key] = result
    return results


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(
        description="PaperClip Design Fetcher — fetch DESIGN.md from awesome-design-md",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python design_fetcher.py list
  python design_fetcher.py list --category "Developer Tools"
  python design_fetcher.py search "dark fintech"
  python design_fetcher.py fetch vercel
  python design_fetcher.py fetch vercel --output ./my-project
  python design_fetcher.py fetch stripe vercel linear --output ./designs
  python design_fetcher.py recommend "minimal dark saas dashboard"
        """
    )

    subparsers = parser.add_subparsers(dest="command", help="Command")

    # list
    list_parser = subparsers.add_parser("list", help="List available brands")
    list_parser.add_argument("--category", "-c", help="Filter by category")

    # search
    search_parser = subparsers.add_parser("search", help="Search brands by query")
    search_parser.add_argument("query", help="Search query")

    # fetch
    fetch_parser = subparsers.add_parser("fetch", help="Fetch DESIGN.md for a brand")
    fetch_parser.add_argument("brands", nargs="+", help="Brand key(s)")
    fetch_parser.add_argument("--output", "-o", default=".", help="Output directory")

    # recommend
    rec_parser = subparsers.add_parser("recommend", help="Recommend brands for a style")
    rec_parser.add_argument("query", help="Style description")
    rec_parser.add_argument("--top", "-n", type=int, default=5, help="Number of results")

    args = parser.parse_args()

    if args.command == "list":
        brands = list_brands(args.category)
        categories = {}
        for key, info in brands:
            cat = info["category"]
            if cat not in categories:
                categories[cat] = []
            categories[cat].append((key, info))

        for cat, cat_brands in categories.items():
            print(f"\n## {cat}")
            for key, info in cat_brands:
                print(f"  {key:<20s} | {info['vibe']}")

    elif args.command == "search":
        results = search_brands(args.query)
        if results:
            print(f"Search results for '{args.query}':\n")
            for key, info, score in results[:15]:
                print(f"  [{info['category']}] {key} ({info['name']}) — score={score}")
                print(f"    {info['vibe']}")
        else:
            print(f"No brands found for '{args.query}'")

    elif args.command == "fetch":
        if len(args.brands) == 1:
            result = fetch_brand(args.brands[0], args.output)
            if result:
                print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            results = fetch_multiple(args.brands, args.output)
            print(json.dumps(results, indent=2, ensure_ascii=False))

    elif args.command == "recommend":
        results = recommend_brands(args.query, args.top)
        print(f"\nTop {args.top} recommendations for '{args.query}':\n")
        for i, (key, info, score) in enumerate(results, 1):
            print(f"  {i}. {key} ({info['name']})")
            print(f"     Category: {info['category']}")
            print(f"     Vibe: {info['vibe']}")
            print(f"     Keywords: {', '.join(info['keywords'])}")
            print()

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
