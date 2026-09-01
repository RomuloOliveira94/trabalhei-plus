import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Accessible delete-confirmation modal (SPEC §8 "Modal de confirmação de
// delete"), replacing Turbo's native data-turbo-confirm browser dialog.
//
// Any element carrying data-confirm (body message) and optionally
// data-confirm-title opens the modal on click. Confirming submits the
// original form (button_to) or follows the original link; cancelling or
// pressing Escape closes it. Focus is trapped inside the dialog while open.
//
// The modal markup lives once in the application layout
// (app/views/shared/_confirm_modal.html.erb).
export default class extends Controller {
  static targets = [ "dialog", "title", "body", "confirmButton", "cancelButton" ]

  connect() {
    this.handleClick = this.handleClick.bind(this)
    document.addEventListener("click", this.handleClick)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClick)
  }

  // Intercept clicks on any [data-confirm] element before the browser
  // submits the wrapping form or follows the link.
  handleClick(event) {
    const element = event.target.closest("[data-confirm]")
    if (!element) return

    event.preventDefault()
    event.stopImmediatePropagation()
    this.open(element)
  }

  open(element) {
    this.elementToConfirm = element
    this.titleTarget.textContent = element.dataset.confirmTitle || this.dialogTarget.dataset.defaultTitle
    this.bodyTarget.textContent = element.dataset.confirm
    if (element.dataset.confirmLabel) this.confirmButtonTarget.textContent = element.dataset.confirmLabel
    if (element.dataset.cancelLabel) this.cancelButtonTarget.textContent = element.dataset.cancelLabel

    if (typeof this.dialogTarget.showModal === "function") {
      this.dialogTarget.showModal()
    } else {
      // Fallback for browsers without <dialog> support.
      this.dialogTarget.setAttribute("open", "")
    }
    this.confirmButtonTarget.focus()
  }

  close() {
    if (typeof this.dialogTarget.close === "function") {
      this.dialogTarget.close()
    } else {
      this.dialogTarget.removeAttribute("open")
    }
    this.elementToConfirm = null
  }

  confirm(event) {
    event.preventDefault()
    const element = this.elementToConfirm
    this.close()
    if (!element) return

    if (element instanceof HTMLFormElement) {
      element.requestSubmit()
    } else if (element.form) {
      // button_to: the button lives inside a form.
      element.form.requestSubmit()
    } else if (element.tagName === "A") {
      Turbo.visit(element.href)
    }
  }

  cancel(event) {
    event.preventDefault()
    this.close()
  }

  // Escape closes the dialog (native for showModal, manual for the fallback);
  // Tab/Shift+Tab keep focus inside the dialog while it is open.
  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    } else if (event.key === "Tab") {
      this.trapFocus(event)
    }
  }

  trapFocus(event) {
    const focusables = this.dialogTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    if (focusables.length === 0) return

    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }
}