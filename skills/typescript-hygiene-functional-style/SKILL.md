---
name: typescript-hygiene-functional-style
description: "Write TypeScript in pure functional style. Small pure functions over readonly data, side effects only at the edges, no mutation and no classes, array pipelines over loops, one expression or one return per function where it reads, errors returned as values, exhaustive matching over discriminated unions, and well-known libraries over hand-rolled code. The user's preferences pick a tier of libraries: the language and its standard library alone, then remeda added, then Immer added; the skill says what each tier uses and what it rules out. Use when writing, rewriting or reviewing TypeScript code, scripts or tests, including a skill's bundled scripts, which stay on the standard-library tier."
---

# Pure functional TypeScript

_A program is a core of small pure functions over readonly data, wrapped in a thin shell at the edges that does the input and output. The tier in the preferences says which libraries the core may use._

## The rules, at every tier

- **Pure core, effects at the edges:** a function in the core takes values and returns a value. Reading files, `process.env`, `Date.now()`, `Math.random()`, `fetch`, `console`, timers and `process.exit` happen only at the edges: the entry point, a request handler, a hook, and the few functions they call, which pass plain values into the core and act on what comes back. The core is synchronous; `async` and `await` stay at the edges.
- **Nothing changes in place:** no `push`, `pop`, `splice`, `sort()`, `reverse()`, `fill`, `Map.set` or `delete` on shared data, and no assignment to a property or an index. Build a new value instead: spread (`[...xs, x]`, `{ ...a, b: 1 }`), `toSorted`, `toReversed`, `toSpliced`, `with`, or the tier's helpers.
- **`const` only:** no `let` or `var`. A value that changes step by step is a pipeline or a `reduce`, not a variable rewritten in a loop.
- **Readonly data, in the types:** parameters and fields are `readonly`, arrays are `ReadonlyArray<T>` or `readonly T[]`, maps and sets are `ReadonlyMap` and `ReadonlySet`, and literal tables are `as const`. A type that leaves its module is `Readonly<...>` all the way down, so the compiler refuses a write anywhere.
- **No classes:** records are type aliases or interfaces of readonly fields, built by plain functions; behaviour is functions over them, never methods that read `this`. `enum` is a union of string literals, and a namespace is a module.
- **Array pipelines over loops:** `map`, `filter`, `flatMap`, `reduce`, `some`, `every`, `find`, `Object.entries` and `Object.fromEntries`, `Object.groupBy` and `Map.groupBy`, and `Array.from({ length: n }, f)` for a range, rather than a `for` loop that fills an array or sets a variable.
- **One expression or one return:** a function is an arrow function with an expression body where it reads, or a body of `const` bindings ending in one `return`. A conditional is a ternary, a lookup in an `as const` table, or a `switch` that returns in every case, never a chain of `if` that sets a variable.
- **Small functions, composed:** each function does one thing and is named for it; a long callback inline in a pipeline is a named function instead. Compose by calling, by passing functions, or by the tier's `pipe`.
- **Errors as values in the core:** a core function that can fail returns a discriminated union, such as `{ readonly ok: true; readonly value: T } | { readonly ok: false; readonly error: E }`, and the caller handles both. `throw` is for bugs and for the edges' I/O; the edge catches it and turns it into an exit code or a response.
- **Exhaustive matching:** a `switch` over a discriminated union's tag ends with a `default` that assigns the value to `never`, or the union is checked with `satisfies`, so a new case fails to compile until every match handles it.
- **No deep recursion:** JavaScript engines other than Safari's don't eliminate tail calls, and the stack runs out after some thousands of frames. Walk a structure of unbounded depth with `reduce` or an explicit worklist inside one function, kept pure from outside.
- **Laziness with care:** an iterator or generator can be read only once, so the core passes arrays between functions and keeps an iterator inside the expression that consumes it.
- **Well-known libraries over hand-rolled code:** parsing, dates, schemas and deep updates come from the tier's libraries or a well-known library the project already has, never a hand-written parser, regular expression or recursive merge. A helper is written only when no library at the tier has it.

## Tiers

The preferences name the tier. Each tier adds to the one before; nothing outside the tier is imported in the core.

### Tier 1: the language and its standard library

- Arrays, returned new: `map`, `filter`, `flatMap`, `reduce`, `toSorted`, `toReversed`, `toSpliced`, `with`, `at`, `Array.from`, `Array.prototype.includes`.
- Objects and maps: spread, `Object.entries`, `Object.fromEntries`, `Object.groupBy`, `Map.groupBy`, `new Map(entries)` built once and typed `ReadonlyMap`, `structuredClone` for a copy that must not share.
- Types: `readonly`, `Readonly<T>`, `ReadonlyArray<T>`, `ReadonlyMap`, `ReadonlySet`, `as const`, `satisfies`, discriminated unions and `never`.
- `Object.freeze` at the boundary, on data the shell hands in, where code outside the compiler's sight may try to write to it.
- Updating a nested object means rebuilding each level on the path: `{ ...d, a: { ...d.a, b: 1 } }`. More than two levels deep is the sign a flatter record would read better.

### Tier 2: remeda added

- Composition: `pipe` for a value through steps and `piped` for a reusable pipeline; remeda's functions work data-first, `R.map(xs, f)`, and data-last inside `pipe`, with types inferred through each step.
- Objects, returned new: `pick`, `omit`, `merge`, `mergeDeep`, `mapValues`, `mapKeys`, `setPath`.
- Arrays: `groupBy`, `indexBy`, `sortBy`, `uniqueBy`, `partition`, `chunk`, `sumBy`, `countBy`, `zip`, `first`, `last`.
- remeda rather than lodash: lodash's `set`, `remove` and `pull` change their argument in place. Import one of them, never both.

### Tier 3: Immer added

- `produce(base, (draft) => { ... })` writes to a draft and returns a new value that shares the unchanged parts and is deeply frozen by default, so a deep update reads as one change instead of a spread at every level.
- The draft's in-place writes stay inside the recipe; the recipe touches nothing else and returns nothing, or returns a whole new value.
- Use `produce` for nested updates and many updates in one step; a flat update is still a spread.
- `castImmutable` and the `Immutable<T>` type mark what `produce` returns as readonly to the compiler.

## Bundled scripts and checks

- **A skill's bundled scripts stay on tier 1,** whatever the preferences say, so they run on Node with nothing installed. Node strips types without a compiler only from erasable syntax, which this style keeps to anyway: no `enum`, namespace or parameter property.
- **Tests test the core directly:** pure functions need no mocks, temporary files or faked clocks. Only the edges' tests touch the file system or the network.
- **Let the tools enforce it:** `strict` and `noUncheckedIndexedAccess` in `tsconfig.json`, and where the project lints, `eslint-plugin-functional`'s rules against `let`, loops, classes, `this` and mutation (`no-let`, `no-loop-statements`, `no-classes`, `no-this-expressions`, `immutable-data`), with `prefer-immutable-types` and `type-declaration-immutability` for readonly types.
- **Reviewing:** flag every in-place change, `let`, loop that fills a value, class, `this`, I/O or `await` inside the core, missing `readonly`, non-exhaustive `switch`, hand-rolled helper a library at the tier has, and import beyond the tier.

## Your preferences

!`cat "$(dirname "${CLAUDE_SKILL_DIR}")/typescript-hygiene-functional-style.preferences.md" "${CLAUDE_PROJECT_DIR}/.agents/skills/typescript-hygiene-functional-style.preferences.md" 2>/dev/null || true`

If your agent doesn't run the line above, read these files yourself if they
exist: `typescript-hygiene-functional-style.preferences.md` next to this skill's folder, then
`.agents/skills/typescript-hygiene-functional-style.preferences.md` in the project. A project's
file overrides the user's, and the user's overrides this skill's defaults.

The keys this skill reads, with its own defaults:

```markdown
- Tier: 1
```

`Tier` is `1` (the language and its standard library), `2` (remeda added) or `3` (Immer added).

## When to apply

- Writing or rewriting TypeScript: an application, a library, a script, a hook, a test.
- Reviewing a TypeScript change.
- Writing a skill's bundled TypeScript script, at tier 1.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `coding-agent-skill-references`: the preferences files this skill reads, and where a user's choice goes.
- `design-hygiene-parsers-over-regular-expressions`: the parser to use for a structured format instead of a hand-written one.
