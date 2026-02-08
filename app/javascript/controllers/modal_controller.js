import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];

  close() {
    this.element.remove();
  }

  closeBackground(event) {
    if (event.target === this.element) {
      this.close();
    }
  }
}
