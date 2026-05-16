import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="auto-submit"
// Submits the closest form whenever a watched input changes.
// Usage: place on the <form> and listen for `change->auto-submit#submit`
// or add data-action on individual fields.
export default class extends Controller {
  submit(event) {
    const form =
      this.element.tagName === "FORM"
        ? this.element
        : this.element.closest("form");
    if (!form) return;

    // Debounce a tiny bit so multiple synchronous changes coalesce.
    clearTimeout(this._timer);
    this._timer = setTimeout(() => {
      if (typeof form.requestSubmit === "function") {
        form.requestSubmit();
      } else {
        form.submit();
      }
    }, 50);
  }
}
