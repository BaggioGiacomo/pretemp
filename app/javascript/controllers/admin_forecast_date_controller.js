import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "datePickerContainer"];

  connect() {
    // Initialize date picker with correct min value based on tendenza state
    this.updateDatePickerBounds();
  }

  onTendenzaChange(event) {
    const isTendenza = this.checkboxTarget.checked;

    // If tendenza is being checked, validate the current date
    if (isTendenza) {
      const dateInput = this.datePickerContainerTarget.querySelector(
        '[data-date-picker-target="input"]',
      );
      const currentDate = this._parse(dateInput.value);
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Calculate T+2
      const tPlus2 = new Date(today);
      tPlus2.setDate(tPlus2.getDate() + 2);

      // If current date is before T+2, automatically set it to T+2
      if (currentDate < tPlus2) {
        dateInput.value = this._formatDate(tPlus2);
        // Dispatch change event to trigger date picker label update
        dateInput.dispatchEvent(new Event("change", { bubbles: true }));
      }
    }

    this.updateDatePickerBounds();
  }

  updateDatePickerBounds() {
    const isTendenza = this.checkboxTarget.checked;
    const datePickerContainer = this.datePickerContainerTarget;

    // Calculate min date based on tendenza state
    let minDate;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (isTendenza) {
      // T+2: day after tomorrow
      minDate = new Date(today);
      minDate.setDate(minDate.getDate() + 2);
    } else {
      // Regular forecasts: disable past dates
      minDate = new Date(today);
    }

    // Update the data attribute
    datePickerContainer.setAttribute(
      "data-date-picker-min-value",
      this._formatDate(minDate),
    );

    // Trigger a custom event to notify the date picker controller
    // This will cause it to re-render with the new bounds
    const event = new CustomEvent("minMaxChanged", {
      detail: { minValue: this._formatDate(minDate) },
      bubbles: true,
    });
    datePickerContainer.dispatchEvent(event);
  }

  _parse(str) {
    if (!str) return null;
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(str);
    if (!m) return null;
    const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
    d.setHours(0, 0, 0, 0);
    return d;
  }

  _formatDate(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
  }
}
