import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["show", "showPart", "form", "field", "pen", "penIcon", "penLine", "editLabel", "header", "line", "input", "submit", "showTitle", "showHook", "showBody"]

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

  resetStyles() {
    this.clearDropStyles([...this.showPartTargets])
    this.clearDropStyles([...this.fieldTargets])
    this.showTarget.style.display = ""
    this.showTarget.style.zIndex = ""
    this.showTarget.style.position = ""
    this.showTarget.style.height = ""
    this.showTarget.style.overflow = ""
    this.formTarget.classList.add("hidden")
    this.formTarget.style.opacity = "0"
    this.formTarget.style.position = ""
    this.formTarget.style.top = ""
    this.formTarget.style.left = ""
    this.formTarget.style.width = ""
    this.formTarget.style.height = ""
    this.formTarget.style.overflow = ""
    this.penIconTarget.style.transition = ""
    this.penIconTarget.style.transform = ""
    this.penLineTarget.style.width = ""
    this.submitTarget.style.display = ""
    this.submitTarget.classList.add("opacity-0", "pointer-events-none")
    this.submitTarget.classList.remove("opacity-100")
    this.showTitleTarget.style.transition = ""
    this.showTitleTarget.style.transform = ""
    this.headerTarget.style.transition = ""
    this.headerTarget.style.marginBottom = ""
    this.headerTarget.style.backgroundColor = ""
    this.headerTarget.style.zIndex = ""
    this.lineTargets.forEach(line => {
      line.classList.remove("w-full")
      line.style.width = ""
      line.style.backgroundColor = ""
    })
    this.inputTargets.forEach(input => {
      input.setAttribute("readonly", true)
      input.classList.add("cursor-default")
      input.classList.remove("cursor-text")
    })
    this.showTitleTarget.contentEditable = "false"
    this.showTitleTarget.style.cursor = ""
    this.showTitleTarget.style.outline = ""
  }

  reveal() {
    this.resetStyles()
    this.editing = true

    this.editLabelTarget.style.opacity = "0"

    this.showTitleTarget.style.transformOrigin = "top left"
    this.showTitleTarget.style.transition = "transform 1.4s cubic-bezier(0.22, 0.61, 0.36, 1)"
    this.showTitleTarget.style.transform = "scale(0.45)"

    this.headerTarget.style.backgroundColor = "transparent"
    this.headerTarget.style.zIndex = "0"
    this.headerTarget.style.transition = "margin-bottom 1.4s cubic-bezier(0.22, 0.61, 0.36, 1)"
    this.headerTarget.style.marginBottom = "-80px"

    const penLine = this.penLineTarget
    penLine.style.width = "0"

    setTimeout(() => {
      const penIcon = this.penIconTarget
      const iconRect = penIcon.getBoundingClientRect()
      const rollDistance = window.innerWidth - iconRect.left
      penIcon.style.transition = "transform 0.8s cubic-bezier(0.25, 0, 0.6, 1)"
      penIcon.style.transform = `translateX(${rollDistance}px) rotate(720deg)`
    }, 500)

    // Lock showTarget height so it doesn't collapse when parts become position: fixed
    this.showTarget.style.height = `${this.showTarget.offsetHeight}px`
    this.showTarget.style.overflow = "hidden"
    
    const parts = [...this.showPartTargets].reverse()
    const allPartsGone = this.dropElements(parts, {
      duration: 0.7,
      onDone: () => {
        this.showTarget.style.display = "none"
        this.clearDropStyles(parts)
        this.formTarget.style.position = ""
        this.formTarget.style.top = ""
        this.formTarget.style.left = ""
        this.formTarget.style.width = ""
        this.formTarget.style.height = ""
      }
    })

    setTimeout(() => {
      const fields = [...this.fieldTargets].reverse()
      
      // 1. Position all fields off-screen while the form is still hidden
      fields.forEach((field) => {
        const dropFrom = window.innerHeight
        field.style.transition = "none"
        field.style.transform = `translateY(-${dropFrom}px)`
        field.style.opacity = "0"
      })

      // 2. Make the form visible (fields render off-screen instantly)
      this.formTarget.classList.remove("hidden")
      this.formTarget.style.opacity = "1"
      this.formTarget.style.position = "absolute"
      this.formTarget.style.top = "0"
      this.formTarget.style.left = "0"
      this.formTarget.style.width = "100%"
      this.formTarget.style.height = "100%"

      // 3. Animate fields down using nested requestAnimationFrames to ensure layout sync
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          fields.forEach((field, index) => {
            setTimeout(() => {
              field.style.transition = "transform 0.8s cubic-bezier(0.22, 0, 0.6, 1), opacity 0.3s ease"
              field.style.transform = "translateY(0)"
              field.style.opacity = "1"
            }, index * 200)
          })
        })
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

        this.showTitleTarget.contentEditable = "true"
        this.showTitleTarget.style.cursor = "text"
        this.showTitleTarget.style.outline = "none"

        const titleInput = this.inputTargets[0]
        titleInput.focus()
        titleInput.setSelectionRange(titleInput.value.length, titleInput.value.length)

        this.submitTarget.style.display = ""
        this.submitTarget.classList.remove("opacity-0", "pointer-events-none")
        this.submitTarget.classList.add("opacity-100")
      }, totalLineTime)
    }, allPartsGone - 400)
  }

  submit() {
    const newTitle = this.showTitleTarget.textContent.trim()
    this.inputTargets[0].value = newTitle.toLowerCase()

    this.showTitleTarget.contentEditable = "false"
    this.showTitleTarget.style.cursor = ""
    this.showTitleTarget.textContent = newTitle.toUpperCase()

    const form = this.element.querySelector("form")
    const formData = new FormData(form)

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(form.action, {
      method: "POST",
      body: formData,
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      }
    }).then(() => this.dispatch('saved'))
    if (this.hasShowHookTarget) this.showHookTarget.textContent = this.inputTargets[1].value
    if (this.hasShowBodyTarget) this.showBodyTarget.textContent = this.inputTargets[2].value

    const fields = [...this.fieldTargets].reverse()
    const elementsToDrop = [this.submitTarget, ...fields]
    this.clearDropStyles(elementsToDrop)

    // Lock form height so it doesn't collapse when fields become fixed
    this.formTarget.style.height = `${this.formTarget.offsetHeight}px`
    this.formTarget.style.overflow = "hidden"

    requestAnimationFrame(() => {
      const fieldsGone = this.dropElements(elementsToDrop)

      setTimeout(() => {
        this.formTarget.classList.add("hidden")
        this.submitTarget.style.display = "none"
        this.clearDropStyles([this.submitTarget])
      }, fieldsGone)

      setTimeout(() => {
        this.showTitleTarget.style.transition = "transform 1.4s cubic-bezier(0.22, 0.61, 0.36, 1)"
        this.showTitleTarget.style.transform = "scale(1)"
        this.headerTarget.style.zIndex = "0"
        this.headerTarget.style.transition = "margin-bottom 1.4s cubic-bezier(0.22, 0.61, 0.36, 1)"
        this.headerTarget.style.marginBottom = ""
      }, fieldsGone)

      const showContentStart = fieldsGone

      setTimeout(() => {
        const show = this.showTarget
        show.style.display = ""
        show.style.zIndex = "1"
        show.style.position = "relative"
        show.style.height = ""
        show.style.overflow = ""

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
            this.editLabelTarget.style.opacity = ""
            this.headerTarget.style.zIndex = ""
            this.headerTarget.style.backgroundColor = ""
            this.editing = false
          }, 800)
        }, allPartsLanded)
      }, showContentStart)
    })
  }
}
