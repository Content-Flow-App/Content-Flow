import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show() {
    const existing = document.getElementById("success-check-overlay")
    if (existing) existing.remove()

    const overlay = document.createElement("div")
    overlay.id = "success-check-overlay"
    overlay.style.cssText = "position:fixed;inset:0;z-index:9999;display:flex;align-items:center;justify-content:center;pointer-events:none;animation:fade-overlay 1.2s ease forwards;"

    overlay.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
           stroke="var(--cf-orange)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"
           style="width:160px;height:160px;background:rgba(200,200,200,0.5);border-radius:50%;padding:30px;">
        <polyline points="4 12 9 17 20 6"
                  style="stroke-dasharray:30;stroke-dashoffset:30;animation:draw-check 0.5s ease forwards 0.2s;"/>
      </svg>
    `

    document.body.appendChild(overlay)
    setTimeout(() => overlay.remove(), 1200)
  }
}
