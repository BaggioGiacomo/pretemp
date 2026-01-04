import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["trigger", "panel", "icon"];
  static values = {
    group: { type: String, default: "" },
    open: { type: Boolean, default: false },
  };

  connect() {
    this.openValue ? this.show(false) : this.hide(false);
  }

  toggle() {
    if (this.openValue) {
      this.hide(true);
    } else {
      this.closeOthersInGroup();
      this.show(true);
    }
  }

  show(animate = true) {
    this.openValue = true;
    const panel = this.panelTarget;

    panel.classList.remove("hidden");

    if (animate) {
      panel.style.height = "auto";
      const height = panel.scrollHeight;
      panel.style.height = "0px";
      panel.offsetHeight;
      panel.style.height = `${height}px`;
      panel.addEventListener(
        "transitionend",
        () => {
          panel.style.height = "auto";
        },
        { once: true }
      );
    }

    if (this.hasIconTarget) this.iconTarget.classList.add("rotate-180");

    this.triggerTarget.setAttribute("aria-expanded", "true");
  }

  hide(animate = true) {
    this.openValue = false;
    const panel = this.panelTarget;

    if (animate) {
      panel.style.height = `${panel.scrollHeight}px`;
      panel.offsetHeight;
      panel.style.height = "0px";
      panel.addEventListener(
        "transitionend",
        () => {
          if (!this.openValue) {
            panel.classList.add("hidden");
            panel.style.height = "";
          }
        },
        { once: true }
      );
    } else {
      panel.classList.add("hidden");
    }

    if (this.hasIconTarget) this.iconTarget.classList.remove("rotate-180");

    this.triggerTarget.setAttribute("aria-expanded", "false");
  }

  closeOthersInGroup() {
    if (!this.groupValue) return;

    const allAccordions = document.querySelectorAll(
      `[data-controller~="accordion"][data-accordion-group-value="${this.groupValue}"]`
    );

    allAccordions.forEach((element) => {
      if (element !== this.element) {
        const controller =
          this.application.getControllerForElementAndIdentifier(
            element,
            "accordion"
          );
        if (controller && controller.openValue) {
          controller.hide(true);
        }
      }
    });
  }
}
