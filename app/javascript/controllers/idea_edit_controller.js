import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["show", "showPart", "form", "field", "pen", "penIcon", "penLine", "line", "input", "submit", "showTitle", "showTopic", "showDescription"]

  connect() {
    this.editing = false
  }

  toggle() {
    if (this.editing) {
      this.submit()
    } else {
      this.reveal()
    }
  }

  dropElements(elements, { stagger = 300, duration = 1.2, onDone = null } = {}) {
    const rects = elements.map(el => el.getBoundingClientRect())

    elements.forEach((el, index) => {
      const rect = rects[index]
      const fallDistance = window.innerHeight - rect.top

      el.style.position = "fixed"
      el.style.top = `${rect.top}px`
      el.style.left = `${rect.left}px`
      el.style.width = `${rect.width}px`
      el.style.height = `${rect.height}px`
      el.style.zIndex = String(100 - index)
      el.style.backgroundColor = "var(--cf-bg)"

      setTimeout(() => {
        el.style.transition = `transform ${duration}s cubic-bezier(0.33, 0, 1, 0.33)`
        el.style.transform = `translateY(${fallDistance}px)`
      }, index * stagger)
    })

    const totalTime = elements.length * stagger + duration * 1000
    if (onDone) setTimeout(onDone, totalTime)
    return totalTime
  }

  clearDropStyles(elements) {
    elements.forEach((el) => {
      el.style.position = ""
      el.style.top = ""
      el.style.left = ""
      el.style.width = ""
      el.style.height = ""
      el.style.zIndex = ""
      el.style.backgroundColor = ""
      el.style.transition = ""
      el.style.transform = ""
      el.style.opacity = ""
    })
  }

  reveal() {
    this.editing = true

    const penLine = this.penLineTarget
    penLine.style.width = "0"

    setTimeout(() => {
      const penIcon = this.penIconTarget
      const iconRect = penIcon.getBoundingClientRect()
      const rollDistance = window.innerWidth - iconRect.left
      penIcon.style.transition = "transform 0.8s cubic-bezier(0.25, 0, 0.6, 1)"
      penIcon.style.transform = `translateX(${rollDistance}px) rotate(720deg)`
    }, 500)

    const parts = [...this.showPartTargets].reverse()
    const allPartsGone = this.dropElements(parts, {
      duration: 0.7,
      onDone: () => {
        this.showTarget.style.display = "none"
        this.clearDropStyles(parts)
      }
    })

    setTimeout(() => {
      this.formTarget.classList.remove("hidden")
      this.formTarget.style.opacity = "1"

      const fields = [...this.fieldTargets].reverse()
      fields.forEach((field, index) => {
        const dropFrom = window.innerHeight
        field.style.transform = `translateY(-${dropFrom}px)`
        field.style.opacity = "0"

        setTimeout(() => {
          field.style.transition = "transform 0.8s cubic-bezier(0.22, 0, 0.6, 1), opacity 0.3s ease"
          field.style.transform = "translateY(0)"
          field.style.opacity = "1"
        }, index * 200)
      })

      const fieldsLanded = this.fieldTargets.length * 200 + 800

      this.lineTargets.forEach((line, index) => {
        setTimeout(() => {
          line.classList.add("w-full")
        }, fieldsLanded + index * 350)
      })

      const totalLineTime = fieldsLanded + this.lineTargets.length * 350 + 700

      setTimeout(() => {
        this.lineTargets.forEach((line) => {
          line.style.backgroundColor = "var(--cf-accent)"
        })

        this.inputTargets.forEach((input) => {
          input.removeAttribute("readonly")
          input.classList.remove("cursor-default")
          input.classList.add("cursor-text")
        })

        const titleInput = this.inputTargets[0]
        titleInput.focus()
        titleInput.setSelectionRange(titleInput.value.length, titleInput.value.length)

        this.submitTarget.classList.remove("opacity-0", "pointer-events-none")
        this.submitTarget.classList.add("opacity-100")
      }, totalLineTime)
    }, allPartsGone - 400)
  }

  submit() {
    const form = this.element.querySelector("form")
    const formData = new FormData(form)

    fetch(form.action, {
      method: form.method || "PATCH",
      body: formData,
      headers: { "Accept": "application/json" }
    })

    this.showTitleTarget.textContent = this.inputTargets[0].value.toUpperCase()
    this.showTopicTarget.textContent = this.inputTargets[1].value
    this.showDescriptionTarget.textContent = this.inputTargets[2].value

    this.submitTarget.classList.add("opacity-0", "pointer-events-none")
    this.submitTarget.classList.remove("opacity-100")

    const fields = [...this.fieldTargets].reverse()
    this.clearDropStyles(fields)

    requestAnimationFrame(() => {
      const fieldsGone = this.dropElements(fields)

      const showStart = fieldsGone - 700

      setTimeout(() => {
        this.formTarget.classList.add("hidden")
      }, fieldsGone)

      setTimeout(() => {
        const show = this.showTarget
        show.style.display = ""
        show.style.zIndex = "1"
        show.style.position = "relative"

        const parts = [...this.showPartTargets].reverse()
        const stagger = 200

        parts.forEach((part) => {
          part.style.transform = `translateY(-${window.innerHeight}px)`
          part.style.transition = "none"
        })

        requestAnimationFrame(() => {
          parts.forEach((part, index) => {
            setTimeout(() => {
              part.style.transition = "transform 1.4s cubic-bezier(0.22, 0, 0.6, 1)"
              part.style.transform = "translateY(0)"
            }, index * stagger)
          })
        })

        this.lineTargets.forEach((line) => {
          line.classList.remove("w-full")
          line.style.backgroundColor = ""
        })

        this.inputTargets.forEach((input) => {
          input.setAttribute("readonly", true)
          input.classList.add("cursor-default")
          input.classList.remove("cursor-text")
        })

        const allPartsLanded = (parts.length - 1) * stagger + 1400

        setTimeout(() => {
          const penIcon = this.penIconTarget
          const penLine = this.penLineTarget
          penIcon.style.transition = "transform 0.8s cubic-bezier(0.25, 0, 0.6, 1)"
          penIcon.style.transform = "translateX(0) rotate(0deg)"

          setTimeout(() => {
            penLine.style.width = ""
            this.editing = false
          }, 800)
        }, allPartsLanded)
      }, showStart)
    })
  }
}
