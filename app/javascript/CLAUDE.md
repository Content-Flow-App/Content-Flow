# JavaScript — Stimulus conventions

All JS in this project is written as Stimulus controllers. No inline scripts, no bare `addEventListener` calls outside a controller.

## Creating a controller

1. Add `app/javascript/controllers/<name>_controller.js` — auto-loaded by `controllers/index.js`.
2. Wire it up in HTML with `data-controller="<name>"`.

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]   // → this.inputTarget / this.inputTargets
  static values  = { url: String }  // → this.urlValue

  connect() { /* called when element enters the DOM */ }
  disconnect() { /* cleanup */ }
}
```

## HTML attributes

| Purpose | Attribute |
|---|---|
| Mount controller | `data-controller="name"` |
| Declare a target | `data-name-target="targetName"` |
| Bind an action | `data-action="click->name#method"` |
| Pass a value | `data-name-url-value="<%= some_path %>"` |

Default event per element (`input`→`input`, `form`→`submit`, `a/button`→`click`) can be omitted: `data-action="name#method"`.

## Adding an external library

1. Pin it in `config/importmap.rb`:
   ```ruby
   pin "library-name", to: "https://cdn.example.com/library.esm.js"
   ```
2. Import it inside the controller that needs it — not globally:
   ```js
   import LibraryName from "library-name"
   ```

## Existing controllers

- `star_rating_controller.js` — mounts `star-rating.js` on a `<select>` for the review rating field.
- `tom_select_controller.js` — mounts `TomSelect` on the movie `<select>` in the bookmark form for searchable dropdown behaviour.
