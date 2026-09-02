import { Controller } from "@hotwired/stimulus"

// Auto-dismisses flash messages after a delay (5s for notice/success, 8s for
// alert/error) with a subtle fade-out. The manual close button (X) triggers
// the same fade-out path, so both routes share one code path.
export default class extends Controller {
  static values = { type: String }

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.delay)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    clearTimeout(this.timeout)
    // The wrapper carries transition-opacity duration-500, so adding
    // opacity-0 fades it out before the element is removed.
    this.element.classList.add("opacity-0")
    setTimeout(() => this.element.remove(), 500)
  }

  get delay() {
    return ["alert", "error"].includes(this.typeValue) ? 8000 : 5000
  }
}