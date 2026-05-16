import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="date-picker"
// A custom calendar popup that writes an ISO date (YYYY-MM-DD) into a hidden input.
// Targets:
//   - input:   the hidden <input> that holds the value
//   - trigger: the button that opens the popup and shows the formatted date
//   - label:   element whose textContent shows the formatted date (or placeholder)
//   - panel:   the popup container
//   - grid:    the element where day cells are rendered
//   - title:   the element that shows "Month Year"
// Values:
//   - min, max: ISO date strings bounding selectable dates
//   - placeholder: text shown when no date is set
export default class extends Controller {
  static targets = ["input", "trigger", "label", "panel", "grid", "title"];
  static values = {
    min: String,
    max: String,
    placeholder: { type: String, default: "Seleziona" },
  };

  connect() {
    this.monthNames = [
      "Gennaio",
      "Febbraio",
      "Marzo",
      "Aprile",
      "Maggio",
      "Giugno",
      "Luglio",
      "Agosto",
      "Settembre",
      "Ottobre",
      "Novembre",
      "Dicembre",
    ];
    this.weekDays = ["L", "M", "M", "G", "V", "S", "D"];

    this._onDocClick = this._onDocClick.bind(this);
    this._onKeydown = this._onKeydown.bind(this);

    const initial = this._parse(this.inputTarget.value);
    const minD = this._parse(this.minValue);
    const maxD = this._parse(this.maxValue);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    this.viewDate =
      initial ||
      (minD && today < minD ? minD : maxD && today > maxD ? maxD : today);
    this._renderLabel();
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
    this._render();
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

  prevMonth(event) {
    event?.stopPropagation();
    this.viewDate = new Date(
      this.viewDate.getFullYear(),
      this.viewDate.getMonth() - 1,
      1,
    );
    this._render();
  }

  nextMonth(event) {
    event?.stopPropagation();
    this.viewDate = new Date(
      this.viewDate.getFullYear(),
      this.viewDate.getMonth() + 1,
      1,
    );
    this._render();
  }

  clear(event) {
    event?.stopPropagation();
    this.inputTarget.value = "";
    this._renderLabel();
    this._dispatchChange();
    this.close();
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

  _parse(str) {
    if (!str) return null;
    const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(str);
    if (!m) return null;
    const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
    d.setHours(0, 0, 0, 0);
    return d;
  }

  _format(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    return `${y}-${m}-${day}`;
  }

  _formatHuman(d) {
    return `${String(d.getDate()).padStart(2, "0")} ${this.monthNames[d.getMonth()].slice(0, 3)} ${d.getFullYear()}`;
  }

  _renderLabel() {
    const current = this._parse(this.inputTarget.value);
    if (this.hasLabelTarget) {
      if (current) {
        this.labelTarget.textContent = this._formatHuman(current);
        this.labelTarget.classList.remove("text-slate-500");
        this.labelTarget.classList.add("text-slate-100");
      } else {
        this.labelTarget.textContent = this.placeholderValue;
        this.labelTarget.classList.add("text-slate-500");
        this.labelTarget.classList.remove("text-slate-100");
      }
    }
  }

  _render() {
    const year = this.viewDate.getFullYear();
    const month = this.viewDate.getMonth();
    this.titleTarget.textContent = `${this.monthNames[month]} ${year}`;

    const firstDay = new Date(year, month, 1);
    // ISO: Monday = 0
    const offset = (firstDay.getDay() + 6) % 7;
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrev = new Date(year, month, 0).getDate();

    const min = this._parse(this.minValue);
    const max = this._parse(this.maxValue);
    const selected = this._parse(this.inputTarget.value);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const cells = [];
    // Weekday header
    for (const w of this.weekDays) {
      cells.push(
        `<div class="text-center text-[10px] uppercase tracking-wider font-medium text-slate-500 py-1.5">${w}</div>`,
      );
    }

    // Leading days from previous month
    for (let i = offset - 1; i >= 0; i--) {
      const day = daysInPrev - i;
      const d = new Date(year, month - 1, day);
      cells.push(this._cellHTML(d, { muted: true, min, max, selected, today }));
    }

    // Current month
    for (let day = 1; day <= daysInMonth; day++) {
      const d = new Date(year, month, day);
      cells.push(
        this._cellHTML(d, { muted: false, min, max, selected, today }),
      );
    }

    // Trailing days to complete grid (6 rows × 7 cols = 42)
    const used = offset + daysInMonth;
    const trailing = Math.ceil(used / 7) * 7 - used;
    for (let day = 1; day <= trailing; day++) {
      const d = new Date(year, month + 1, day);
      cells.push(this._cellHTML(d, { muted: true, min, max, selected, today }));
    }

    this.gridTarget.innerHTML = cells.join("");
  }

  _cellHTML(d, { muted, min, max, selected, today }) {
    const iso = this._format(d);
    const disabled = (min && d < min) || (max && d > max);
    const isSelected = selected && d.getTime() === selected.getTime();
    const isToday = d.getTime() === today.getTime();

    let classes =
      "relative h-8 w-8 mx-auto flex items-center justify-center text-xs rounded-lg transition-colors";
    if (disabled) {
      classes += " text-slate-700 cursor-not-allowed";
    } else if (isSelected) {
      classes += " bg-sky-500 text-slate-950 font-semibold";
    } else if (muted) {
      classes += " text-slate-600 hover:bg-slate-800/60 hover:text-slate-300";
    } else {
      classes += " text-slate-200 hover:bg-slate-800";
    }
    if (isToday && !isSelected) classes += " ring-1 ring-sky-500/60";

    return `<button type="button" class="${classes}"
              ${disabled ? "disabled" : ""}
              data-action="click->date-picker#select"
              data-date="${iso}">${d.getDate()}</button>`;
  }

  select(event) {
    event.stopPropagation();
    const iso = event.currentTarget.dataset.date;
    if (!iso) return;
    this.inputTarget.value = iso;
    this._renderLabel();
    this._dispatchChange();
    this.close();
  }

  _dispatchChange() {
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }));
  }
}
