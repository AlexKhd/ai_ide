import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "output"]

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

  askAi() {
    if (!this.editor) {
      this.outputTarget.innerText = "Editor not ready yet!"
      return
    }

    const code = this.editor.getValue()

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
        this.outputTarget.innerText = data.suggestion
      })
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
