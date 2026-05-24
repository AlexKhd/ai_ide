import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"
import Prism from "prismjs"
import "prismjs/components/prism-ruby.js" // add other languages as needed
import "prismjs/themes/prism-tomorrow.css" // dark theme

export default class extends Controller {
  static targets = ["container", "output", "outputerror"]

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
        value: "// Write your Ruby code here\nputs 'Hello AI IDE!'",
        language: "ruby",
        theme: "vs-dark",
        automaticLayout: true
      })
    })
  }

  askAiSse(event) {
    //const chunk = JSON.parse("Your Ruby code is almost correct! ")?.content || ""
    const button = event.currentTarget
    const code = this.editor.getValue()
    const aiConnectionId = 3
    const url = `/ai/code_suggestsse?ai_connection_id=${aiConnectionId}&code=${encodeURIComponent(code)}`

    // ✅ Proper EventSource scoping
    this.evtSource = new EventSource(url)  // Class property
    this.buffer = ""
    this.i = 0

    this.evtSource.onmessage = (event) => this.handleChunk(event)
    this.evtSource.onerror = (err) => this.handleError(err)
  }

  handleChunk(event) {
    //const chunk = JSON.parse(event.data)?.content || ""
    const chunk = JSON.parse(event.data) || ""

    if (chunk === "[DONE]") {
      this.finishTyping()
      return
    }

    this.buffer += chunk
    if (this.i === 0) this.renderTypingEffect()
  }

  renderTypingEffect() {
    const slice = this.buffer.slice(0, this.i + 1)
    this.outputTarget.innerHTML = marked.parse(slice)
    Prism.highlightAll()

    this.i++
    if (this.i < this.buffer.length) {
      requestAnimationFrame(() => this.renderTypingEffect())
    }
  }

  finishTyping() {
    this.evtSource?.close()
    this.setLoading(document.querySelector("#ask-ai"), false)
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
    this.showError(`Connection failed!${err}`)
    this.finishTyping()
  }

  showError(message) {
    this.outputerrorTarget.innerHTML = `<div class="text-red-500">${message}</div>`
  }

  askAi(event) {  // ✅ Add event param
    if (!this.editor) {
      this.outputTarget.innerText = "Editor not ready yet!"
      return
    }

    const code = this.editor.getValue()
    const button = event.currentTarget

    button.disabled = true
    button.classList.add("opacity-50", "cursor-not-allowed")
    this.outputTarget.innerText = "Thinking..."

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
    })
    .catch(error => {
      this.outputTarget.innerHTML = `Error: ${error.message}`
    })
    .finally(() => {
      button.disabled = false
      button.classList.remove("opacity-50", "cursor-not-allowed")
    })
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
