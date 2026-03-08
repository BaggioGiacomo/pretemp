import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "preview", "previewImage"];

  show() {
    const file = this.inputTarget.files[0];
    if (!file) return;

    const url = URL.createObjectURL(file);
    this.previewImageTarget.src = url;
    this.previewTarget.classList.remove("hidden");
  }
}
