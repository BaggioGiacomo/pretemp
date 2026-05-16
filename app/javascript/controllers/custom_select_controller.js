import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="custom-select"
// A styled select built on top of a hidden <input>.
// Targets:
//   - input:   hidden input holding the value
//   - trigger: button opening the panel
//   - label:   element showing the current option label
//   - panel:   options container
// Each option is a <button data-custom-select-target="option" data-value="..."> inside the panel.
export default class extends Controller {
  static targets = ["input", "trigger", "label", "panel", "option"];
  static values = {
    placeholder: { type: String, default: "Seleziona" },
  };

  connect() {
    this._onDocClick = this._onDocClick.bind(this);
    this._onKeydown = this._onKeydown.bind(this);
    this._renderLabel();
    this._markSelected();
  }

  disconnect() {
    document.removeEventListener("click", this._onDocClick);
    document.removeEventListener("keydown", this._onKeydown);
  }

  toggle(event) {
    event?.stopPropagation();
    if (this.panelTarget.classList.contains("hidden")) this.open();
    else this.close();
  }

  open() {
    this.panelTarget.classList.remove("hidden");
    this.triggerTarget.setAttribute("aria-expanded", "true");
    requestAnimationFrame(() => {
      document.addEventListener("click", this._onDocClick);
      document.addEventListener("keydown", this._onKeydown);
    });
  }

  close() {
    this.panelTarget.classList.add("hidden");
    this.triggerTarget.setAttribute("aria-expanded", "false");
    document.removeEventListener("click", this._onDocClick);
    document.removeEventListener("keydown", this._onKeydown);
  }

  select(event) {
    event.stopPropagation();
    const btn = event.currentTarget;
    const value = btn.dataset.value || "";
    this.inputTarget.value = value;
    this._renderLabel(btn.dataset.label || btn.textContent.trim(), value);
    this._markSelected();
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }));
    this.close();
  }

  _renderLabel(text, value) {
    if (!this.hasLabelTarget) return;
    let displayText = text;
    if (displayText == null) {
      const current = this.optionTargets.find(
        (o) => o.dataset.value === this.inputTarget.value,
      );
      displayText = current
        ? current.dataset.label || current.textContent.trim()
        : this.placeholderValue;
      value = this.inputTarget.value;
    }
    this.labelTarget.textContent = displayText;
    if (!value) {
      this.labelTarget.classList.add("text-slate-500");
      this.labelTarget.classList.remove("text-slate-100");
    } else {
      this.labelTarget.classList.remove("text-slate-500");
      this.labelTarget.classList.add("text-slate-100");
    }
  }

  _markSelected() {
    const value = this.inputTarget.value;
    this.optionTargets.forEach((opt) => {
      const isSel = opt.dataset.value === value;
      opt.classList.toggle("bg-slate-800", isSel);
      opt.classList.toggle("text-white", isSel);
    });
  }

  _onDocClick(event) {
    if (!this.element.contains(event.target)) this.close();
  }

  _onKeydown(event) {
    if (event.key === "Escape") {
      this.close();
      this.triggerTarget.focus();
    }
  }
}
