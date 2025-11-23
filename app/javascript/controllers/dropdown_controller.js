import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["panel"];

  connect() {
    this.close();
    this.handleClickOutside = this.handleClickOutside.bind(this);
    document.addEventListener("click", this.handleClickOutside);
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside);
  }

  toggle(event) {
    if (event) event.preventDefault();
    this.isOpen() ? this.close() : this.open();
  }

  open() {
    if (!this.hasPanelTarget) return;

    this.element.dataset.open = "true";
    this.panelTarget.dataset.hidden = "false";
  }

  close() {
    if (!this.hasPanelTarget) return;

    this.element.dataset.open = "false";
    this.panelTarget.dataset.hidden = "true";
  }

  isOpen() {
    return this.element.dataset.open === "true";
  }

  handleClickOutside(event) {
    if (!this.isOpen()) return;
    if (this.element.contains(event.target)) return;

    this.close();
  }
}
