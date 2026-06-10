import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Visits the given URL as soon as the element enters the DOM. GenerationJob
// broadcasts an element wired to this controller over the chat's Turbo Stream
// once the record is saved, which navigates the user to its show page —
// Stimulus `connect()` fires when Turbo inserts the broadcast element, so no
// listener wiring is needed. Turbo.visit (rather than location.assign) keeps
// the navigation inside Turbo Drive: no full page reload.
export default class extends Controller {
  static values = { url: String }

  connect() {
    Turbo.visit(this.urlValue)
  }
}
