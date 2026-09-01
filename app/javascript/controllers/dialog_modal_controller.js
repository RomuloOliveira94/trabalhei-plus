import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Custom Turbo Stream action emitted by the create/update success streams so
// the modal closes after the list row is appended/replaced. Registered once
// at import time; the controller listens for the matching DOM event.
Turbo.StreamActions.close_modal = function () {
  document.dispatchEvent(new CustomEvent("dialog-modal:close"))
}

// Accessible CRUD modal (Phase 5 follow-up): "Nova hora extra" and "Editar"
// open a <dialog> and load the form into a Turbo Frame inside it. The frame
// keeps the existing Turbo Stream behaviour — success streams append/replace
// the list row and emit close_modal; a 422 re-renders the form HTML into the
// frame so validation errors stay visible inside the open modal.
//
// The modal markup lives once in the application layout
// (app/views/shared/_dialog_modal.html.erb). Triggers carry
// data-dialog-modal-url-value and data-dialog-modal-title-value.
export default class extends Controller {
  static targets = [ "dialog", "body" ]

  connect() {
    this.handleClick = this.handleClick.bind(this)
    this.handleCloseStream = this.handleCloseStream.bind(this)
    this.handleFrameLoad = this.handleFrameLoad.bind(this)
    // A document listener is used because the triggers ("Nova hora extra"
    // buttons, "Editar" links) live outside this controller's scope, and
    // Stimulus 3.2.2 does not dispatch actions for out-of-scope elements —
    // same pattern as the confirm-modal controller.
    document.addEventListener("click", this.handleClick)
    document.addEventListener("dialog-modal:close", this.handleCloseStream)
    // turbo:frame-load bubbles, so a single listener on the dialog survives
    // the frame element being replaced by the create/update streams.
    this.dialogTarget.addEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClick)
    document.removeEventListener("dialog-modal:close", this.handleCloseStream)
    this.dialogTarget.removeEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  // Intercept clicks on any [data-dialog-modal-url-value] trigger before the
  // browser follows the link (or Turbo visits it).
  handleClick(event) {
    const trigger = event.target.closest("[data-dialog-modal-url-value]")
    if (!trigger) return

    event.preventDefault()
    this.open(trigger)
  }

  open(trigger) {
    const url = trigger.dataset.dialogModalUrlValue
    const title = trigger.dataset.dialogModalTitleValue
    this.lastFocused = trigger
    if (this.dialogTarget.open) this.dialogTarget.close()
    this.dialogTarget.setAttribute("aria-label", title)
    this.dialogTarget.showModal()
    // Reset the frame so reopening always fetches a fresh form.
    const frame = this.frame
    frame.removeAttribute("src")
    frame.innerHTML = ""
    frame.src = url
    // If the form is already loaded (cached frame), focus it right away.
    this.focusFirstInput()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
    const frame = this.frame
    frame.removeAttribute("src")
    frame.innerHTML = ""
    this.lastFocused?.focus()
    this.lastFocused = null
  }

  handleCloseStream() {
    this.close()
  }

  handleFrameLoad(event) {
    if (event.target.matches("turbo-frame#overtime_form")) this.focusFirstInput()
  }

  focusFirstInput() {
    // Skip hidden inputs (authenticity_token, from/to) — they are not
    // focusable, so the first visible field gets the focus.
    const input = this.dialogTarget.querySelector('input:not([type="hidden"]), select, textarea')
    input?.focus()
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

  // Click on the backdrop or on any [data-dialog-modal-close] element (the
  // form's "Cancelar" link) closes the modal. Clicks inside the dialog box
  // are ignored so the form stays interactive.
  clicked(event) {
    if (event.target.closest("[data-dialog-modal-close]")) {
      event.preventDefault()
      this.close()
      return
    }
    const rect = this.dialogTarget.getBoundingClientRect()
    const inside = event.clientX >= rect.left && event.clientX <= rect.right &&
      event.clientY >= rect.top && event.clientY <= rect.bottom
    if (!inside) this.close()
  }

  get frame() {
    return this.dialogTarget.querySelector("turbo-frame#overtime_form")
  }
}