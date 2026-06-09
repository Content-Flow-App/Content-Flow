import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "link"]

  moveTo(event) {
    const link = event.currentTarget
    const containerRect = this.element.getBoundingClientRect()
    const linkRect = link.getBoundingClientRect()

    const wasHidden = this.lineTarget.style.opacity === "0" || !this.lineTarget.style.opacity

    if (wasHidden) {
      const originalTransition = this.lineTarget.style.transition
      this.lineTarget.style.transition = "none"
      this.lineTarget.style.width = `${linkRect.width}px`
      this.lineTarget.style.transform = `translateX(${linkRect.left - containerRect.left}px)`
      
      // Force layout recalculation
      void this.lineTarget.offsetHeight

      this.lineTarget.style.transition = originalTransition
      this.lineTarget.style.opacity = "1"
    } else {
      this.lineTarget.style.width = `${linkRect.width}px`
      this.lineTarget.style.transform = `translateX(${linkRect.left - containerRect.left}px)`
      this.lineTarget.style.opacity = "1"
    }
  }

  hide() {
    this.lineTarget.style.opacity = "0"
  }
}
