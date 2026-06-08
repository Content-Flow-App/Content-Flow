import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "link"]

  moveTo(event) {
    const link = event.currentTarget
    const containerRect = this.element.getBoundingClientRect()
    const linkRect = link.getBoundingClientRect()

    this.lineTarget.style.width = `${linkRect.width}px`
    this.lineTarget.style.transform = `translateX(${linkRect.left - containerRect.left}px)`
    this.lineTarget.style.opacity = "1"
  }

  hide() {
    this.lineTarget.style.opacity = "0"
  }
}
