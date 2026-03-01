# Classe

[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Creator Store](https://img.shields.io/badge/Creator%20Store-Classe-brightgreen)](https://create.roblox.com/store/asset/86601565246465/Classe)
[![GitHub](https://img.shields.io/badge/github-Podushka--Hrenov%2FClasse-181717?logo=github)](https://github.com/Podushka-Hrenov/Classe)

![Classe Banner](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/1/1/e/a/11ea6db11e63f8daaf7866617f0b2f3eabb080a8.png)

**Highly typed, simple, fast OOP constructor for Luau.**

Classe solves class organization, typing, and performance issues in Luau. It automatically infers object types — including inheritance — without requiring manual type definitions or metatable boilerplate. It also avoids `__index` chains for better method call performance.

> [!WARNING]
> The **Beta Luau Type Solver** must be enabled in Roblox Studio settings.

---

## Autocomplete Demo

<iframe width="560" height="315" src="https://www.youtube.com/embed/QEZ2Zko1608?si=hxvQobBdScI1ApnL" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

---

## Basic Class

```luau
local Classe = require(script.Parent.Classe)

local Weapon = Classe.meta({} :: {
    bullets: number
}, {})

type Self  = Classe.Self<typeof(Weapon)>
type ISelf = Classe.ISelf<typeof(Weapon)>

function Weapon.construct(self: ISelf)
    self.bullets = 10
end

function Weapon.shot(self: Self)
    self.bullets -= 1
    print("Boom!")
end

return Classe.build(Weapon)
```

---

## Inheritance

```luau
local Classe = require(script.Parent.Classe)
local Weapon = require(script.Parent.Weapon)

local Rifle, super = Classe.meta({} :: {
    isAiming: boolean
}, {}, Weapon)

type Self  = Classe.Self<typeof(Rifle)>
type ISelf = Classe.ISelf<typeof(Rifle)>

function Rifle.construct(self: ISelf)
    super(self)             -- call parent's construct
    self.isAiming = false
end

-- init is called after construct, with no extra arguments.
-- All parent inits run before child inits.
function Rifle.init(self: Self)
    print("bullets:", self.bullets)
end

function Rifle.aim(self: Self)
    self.isAiming = true
    print("aiming...")
end

return Classe.build(Rifle)
```

---

## API

### `Classe.meta(attrs, meta, extends?)`

Declares the shape of a class. Returns the meta table, and optionally the parent's `_construct` as `super`.

| Parameter | Type      | Description                                                 |
| --------- | --------- | ----------------------------------------------------------- |
| `attrs`   | `table`   | Type-level hint for instance attributes — no runtime effect |
| `meta`    | `table`   | Table where you define `construct`, `init`, and methods     |
| `extends` | `Classe?` | Optional parent class to inherit from                       |

---

### `Classe.build(meta)`

Builds and returns a frozen class object.

| Field               | Description                                                                        |
| ------------------- | ---------------------------------------------------------------------------------- |
| `MyClass.new(...)`  | Creates an instance. Calls `construct`, sets metatable, then runs the `init` chain |
| `MyClass.meta`      | Internal meta table (`__index` holds all methods)                                  |
| `MyClass.parent`    | Reference to the parent class, if any                                              |
| `MyClass.childs`    | List of classes that extend this one                                               |
| `MyClass.overrides` | Keys this class explicitly overrides from its parent                               |

---

## `construct` vs `init`

| Function               | Signature                     | Purpose                                                                                 |
| ---------------------- | ----------------------------- | --------------------------------------------------------------------------------------- |
| `construct(self, ...)` | Receives all `.new(...)` args | **Required.** Sets up instance fields.                                                  |
| `init(self)`           | No extra args                 | **Optional.** Post-construction setup. Runs for every class in the hierarchy, top-down. |

---

## Type Helpers

| Type        | Usage                                                            |
| ----------- | ---------------------------------------------------------------- |
| `Self<M>`   | Full self type (attributes + methods). Use for regular methods.  |
| `ISelf<M>`  | Self with all attributes typed as `any`. Use inside `construct`. |
| `Classe<M>` | Type of the built class object itself.                           |

---

## Performance

Classe is primarily focused on **performance over memory**.

During inheritance, the parent's metadata is copied into the child — avoiding `__index` chains and multi-level lookups entirely. Only function references and primitive values are copied, so the memory overhead is minimal.

If a parent class method is updated after build, `__newindex` automatically propagates the change to all child classes that haven't overridden that key.

> Benchmarked at the **99th level of inheritance** with 500k method call tests — still fast.

![Benchmark](https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/5X/1/9/1/8/191840e3e99435333bc5934e3ae0536d9f5f2782.jpeg)

---

## Notes

- `construct` and `init` are removed from the meta table after `Classe.build` — do not call them directly afterward.
- Metamethods (keys starting with `__`) stay on the meta table and are **not** moved into `__index`.
- Assigning `nil` to a class key (e.g. `MyClass.someMethod = nil`) reverts it to the parent's value.
