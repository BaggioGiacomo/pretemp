import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["trigger", "panel", "icon"];
  static values = {
    hover: { type: Boolean, default: false },
    open: { type: Boolean, default: false },
  };

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this);
    this.closeOnEscape = this.closeOnEscape.bind(this);

    if (!this.openValue) this.panelTarget.classList.add("hidden");
  }

  disconnect() {
    this.removeGlobalListeners();
  }

  toggle(event) {
    event?.stopPropagation();
    this.openValue ? this.close() : this.open();
  }

  open() {
    if (this.openValue) return;

    this.closeOtherDropdowns();
    this.openValue = true;
    this.panelTarget.classList.remove("hidden");

    requestAnimationFrame(() => {
      this.panelTarget.classList.add("animate-in");
    });

    if (this.hasIconTarget) this.iconTarget.classList.add("rotate-180");

    if (this.hasTriggerTarget)
      this.triggerTarget.setAttribute("aria-expanded", "true");

    requestAnimationFrame(() => {
      document.addEventListener("click", this.closeOnClickOutside);
      document.addEventListener("keydown", this.closeOnEscape);
    });
  }

  close() {
    if (!this.openValue) return;

    this.openValue = false;
    this.panelTarget.classList.remove("animate-in");
    this.panelTarget.classList.add("hidden");

    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-180");
    }

    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", "false");
    }

    this.removeGlobalListeners();
  }

  // Hover support
  mouseEnter() {
    if (this.hoverValue) {
      this.hoverTimeout && clearTimeout(this.hoverTimeout);
      this.open();
    }
  }

  mouseLeave() {
    if (this.hoverValue) {
      this.hoverTimeout = setTimeout(() => this.close(), 150);
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close();
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close();
      this.triggerTarget?.focus();
    }
  }

  closeOtherDropdowns() {
    const nav = this.element.closest("nav");
    if (!nav) return;

    nav.querySelectorAll('[data-controller~="dropdown"]').forEach((el) => {
      if (el !== this.element) {
        const controller =
          this.application.getControllerForElementAndIdentifier(el, "dropdown");
        if (controller?.openValue) controller.close();
      }
    });
  }

  removeGlobalListeners() {
    document.removeEventListener("click", this.closeOnClickOutside);
    document.removeEventListener("keydown", this.closeOnEscape);
  }
}
