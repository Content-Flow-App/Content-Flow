import { Controller } from "@hotwired/stimulus"

// Disables every element declared as a "button" target once the form submits,
// preventing a double-click from firing two extraction requests.
export default class extends Controller {
  static targets = ["button"]

  submit() {
    this.buttonTargets.forEach(b => { b.disabled = true })
  }
}
