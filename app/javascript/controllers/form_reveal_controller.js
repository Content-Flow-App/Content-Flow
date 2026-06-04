import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["line", "input", "submit"]

  reveal() {
    this.lineTargets.forEach((line, index) => {
      setTimeout(() => {
        line.classList.add("w-full")
      }, index * 350)
    })

    const totalLineTime = this.lineTargets.length * 350 + 700

    setTimeout(() => {
      this.lineTargets.forEach((line) => {
        line.style.backgroundColor = "var(--cf-accent)"
      })

      this.inputTargets.forEach((input) => {
        input.removeAttribute("readonly")
        input.classList.remove("cursor-default")
        input.classList.add("cursor-text")
      })

      this.inputTargets[0].focus()
    }, totalLineTime)

    setTimeout(() => {
      this.submitTarget.classList.remove("opacity-0", "pointer-events-none")
      this.submitTarget.classList.add("opacity-100")
    }, totalLineTime + 400)
  }

  submit() {
    const btn = this.submitTarget
    btn.style.backgroundColor = "var(--cf-accent)"
    btn.style.borderColor = "var(--cf-accent)"
    btn.style.color = "var(--cf-fg-inverse)"

    setTimeout(() => {
      document.getElementById("creator-form").requestSubmit()
    }, 400)
  }
}
