import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import Prism from "prismjs"
import "prismjs/components/prism-ruby.js" // add other languages as needed
import "prismjs/themes/prism-tomorrow.css" // dark theme

export default class extends Controller {
  static targets = ["container", "output", "outputerror", "formarea", "submitButton"]

  connect() {
    this.initializeMonaco()
  }

  initializeMonaco() {
    require.config({
      paths: {
        vs: "https://cdn.jsdelivr.net/npm/monaco-editor@0.55.1/min/vs"
      }
    })

    require(["vs/editor/editor.main"], () => {
      this.editor = monaco.editor.create(this.containerTarget, {
        value: "// Just for display code",
        language: "ruby",
        theme: "vs-dark",
        automaticLayout: true
      })
    })
  }

  askAiSse(event) {
    const button = event.currentTarget
    const code = this.editor.getValue()
    const aiConnectionId = 3
    const url = `/ai/code_suggestsse?ai_connection_id=${aiConnectionId}&code=${encodeURIComponent(code)}`

    // ✅ Proper EventSource scoping
    this.evtSource = new EventSource(url)  // Class property
    this.buffer = ""
    this.i = 0
    this.isTyping = false

    this.setLoading(button, true)
    this.evtSource.onmessage = (event) => this.handleChunk(event)
    this.evtSource.onerror = (err) => this.handleError(err)
  }

  handleChunk(event) {
    const data = event.data.trim()
    if (!data) return  // Skip empty chunks

    const chunk = JSON.parse(data) || ""

    if (chunk === "[DONE]") {
      this.finishTyping()
      return
    }

    this.buffer += chunk

    // Start typing effect if not already running
    if (!this.isTyping) {
      this.isTyping = true
      this.renderTypingEffect()
    }
  }

  renderTypingEffect() {
    const slice = this.buffer.slice(0, this.i + 1)
    this.outputTarget.innerHTML = marked.parse(slice)
    Prism.highlightAll()

    this.i++
    if (this.i < this.buffer.length) {
      requestAnimationFrame(() => this.renderTypingEffect())
    } else {
      this.isTyping = false
    }
  }

  finishTyping() {
    this.evtSource?.close()
    const button = document.querySelector("#ask-ai")
    if (button) {
      this.setLoading(button, false)
    }
    Prism.highlightAll()
  }

  setLoading(button, loading) {
    button.disabled = loading
    if (loading) {
      button.classList.add("opacity-50", "cursor-not-allowed")
      this.outputTarget.innerText = "Thinking..."
    } else {
      button.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }

  handleError(err) {
    this.showError(`Connection failed! ${err}`)
    this.finishTyping()
  }

  showError(message) {
    this.outputerrorTarget.innerHTML = `<div class="text-red-500">${message}</div>`
  }

  toggleButton() {
    const queryInput = document.getElementById("queryarea")
    const isValueEmpty = !queryInput || queryInput.value.trim() === ""

    this.submitButtonTarget.classList.toggle("hidden", isValueEmpty)
  }

  askAi(event) {  // ✅ Add event param
    if (!this.editor) {
      this.outputTarget.innerText = "Editor not ready yet!"
      return
    }

    const queryInput = this.element.querySelector("#queryarea")
    const code = queryInput ? queryInput.value : ""

    const button = event.currentTarget

    this.setLoading(button, true)

    const form = document.querySelector("[data-editor-target=formarea]");

    if (!form) throw new Error('Form not found');

    // Now safely create FormData
    const formData = new FormData(form);
    const params = Object.fromEntries(formData);

    console.log('params');
    console.log(params);

    // Send AJAX request
    fetch("/ai/code_suggest", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify({ code: code })
    })
    .then(res => res.json())
    .then(data => {
      this.outputTarget.innerHTML = marked.parse(data.suggestion)
      Prism.highlightAll()
    })
    .catch(error => {
      this.showError(`Error: ${error.message}`)
    })
    .finally(() => {
      this.setLoading(button, false)
      queryInput.value = ""
      this.submitButtonTarget.classList.add("hidden")
    })
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
