import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "fileName"];

  show() {
    const file = this.inputTarget.files[0];
    if (!file) return;

    this.fileNameTarget.textContent = file.name;
    this.previewTarget.classList.remove("hidden");
  }
}
