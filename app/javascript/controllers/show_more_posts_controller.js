import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["extra", "buttonText", "arrow"]

  connect() {
    this.expanded = false
  }

  toggle() {
    this.expanded = !this.expanded
    
    if (this.expanded) {
      this.extraTarget.classList.remove("hidden")
      if (this.hasButtonTextTarget) this.buttonTextTarget.textContent = "see less"
      if (this.hasArrowTarget) this.arrowTarget.style.transform = "rotate(-90deg)"
    } else {
      this.extraTarget.classList.add("hidden")
      if (this.hasButtonTextTarget) this.buttonTextTarget.textContent = "see more"
      if (this.hasArrowTarget) this.arrowTarget.style.transform = "rotate(90deg)"
    }
  }
}
