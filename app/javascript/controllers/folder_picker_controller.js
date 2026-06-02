import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["browser"]

  selectedFolder = null

  connect() {
    console.log('FolderPicker connected')
  }

  async openBrowseDialog(event) {
    event.preventDefault()
    console.log('Opening browse dialog')

    try {
      const response = await fetch('/app_folders/browse_working_directory')
      const data = await response.json()

      if (data.error) {
        alert(`Error: ${data.error}`)
        return
      }

      this.renderFolders(data.folders)
      this.browserTarget.classList.remove("hidden")
    } catch (error) {
      console.error("Error fetching folders:", error)
      alert("Failed to load folders")
    }
  }

  renderFolders(folders) {
    const foldersList = document.getElementById("folders-list")
    foldersList.innerHTML = ""

    if (folders.length === 0) {
      foldersList.innerHTML = '<div class="text-sm text-slate-500">No folders found in working directory</div>'
      return
    }

    folders.forEach(folder => {
      const div = document.createElement("div")
      div.className = "flex items-center justify-between rounded bg-white p-3 cursor-pointer hover:bg-purple-100 border border-slate-200"
      div.innerHTML = `
        <div class="flex-1">
          <span class="text-sm font-medium">${folder.name}</span>
          <span class="text-xs text-slate-500 ml-2">${folder.file_count} files</span>
        </div>
        <span class="text-lg">📁</span>
      `
      div.addEventListener("click", () => this.selectFolderItem(folder))
      foldersList.appendChild(div)
    })
  }

  selectFolderItem(folder) {
    this.selectedFolder = folder
    // Visual feedback
    document.querySelectorAll("#folders-list > div").forEach(el => {
      el.classList.remove("bg-purple-200", "border-purple-500")
    })
    event.currentTarget.classList.add("bg-purple-200", "border-purple-500")
  }

  selectFolder(event) {
    event.preventDefault()

    if (!this.selectedFolder) {
      alert("Please select a folder first")
      return
    }

    document.getElementById("app_folder_path").value = this.selectedFolder.path

    this.closeBrowser(event)
  }

  closeBrowser(event) {
    event.preventDefault()
    this.browserTarget.classList.add("hidden")
    this.selectedFolder = null
  }
}
