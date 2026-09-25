import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["toggleable"]

  toggle(event) {
    // Prevent toggling if clicking interactive controls
    if (["A", "BUTTON", "INPUT", "TEXTAREA"].includes(event.target.tagName)) return

    if (this.hasToggleableTarget) {
      this.toggleableTarget.classList.toggle("hidden")
    } else if (this.element.nextElementSibling) {
      this.element.nextElementSibling.classList.toggle("hidden")
    }
  }
}
