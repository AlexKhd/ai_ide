import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "trigger"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }

  connect() {
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}
