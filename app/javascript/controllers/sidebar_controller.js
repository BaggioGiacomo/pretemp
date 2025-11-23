import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["button", "panel"];

  connect() {}

  disconnect() {}

  toggle() {
    if (this.panelTarget.dataset.hidden === "true") {
      this.panelTarget.dataset.hidden = "false";
      this.buttonTarget.textContent = "✕";
    } else {
      this.panelTarget.dataset.hidden = "true";
      this.buttonTarget.textContent = "☰";
    }
  }
}
