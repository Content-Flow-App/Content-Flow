import { Controller } from "@hotwired/stimulus"

// Provides a "refreshing..." loading state for the feed refresh button.
// Attach with data-controller="refresh" on the form, and
// data-action="refresh#spin" on the submit button.
export default class extends Controller {
  static targets = ["button"]

  spin() {
    if (!this.hasButtonTarget) return
    this.buttonTarget.value = "refreshing..."
    this.buttonTarget.disabled = true
  }
}
