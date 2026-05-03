import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="slideshow"
export default class extends Controller {
  static targets = ["slide", "indicator"];
  static values = {
    interval: { type: Number, default: 5000 },
    index: { type: Number, default: 0 },
  };

  connect() {
    this.show(this.indexValue);
    this.start();
  }

  disconnect() {
    this.stop();
  }

  start() {
    this.stop();
    if (this.slideTargets.length <= 1) return;
    this.timer = setInterval(() => this.next(), this.intervalValue);
  }

  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  next() {
    this.show((this.indexValue + 1) % this.slideTargets.length);
    this.start();
  }

  prev() {
    const total = this.slideTargets.length;
    this.show((this.indexValue - 1 + total) % total);
    this.start();
  }

  goTo(event) {
    const index = parseInt(event.currentTarget.dataset.slideshowIndexParam, 10);
    if (Number.isNaN(index)) return;
    this.show(index);
    this.start();
  }

  show(index) {
    this.indexValue = index;
    this.slideTargets.forEach((slide, i) => {
      const active = i === index;
      slide.classList.toggle("opacity-100", active);
      slide.classList.toggle("opacity-0", !active);
      slide.classList.toggle("pointer-events-none", !active);
      slide.setAttribute("aria-hidden", active ? "false" : "true");
    });
    if (this.hasIndicatorTarget) {
      this.indicatorTargets.forEach((dot, i) => {
        const active = i === index;
        dot.classList.toggle("bg-sky-400", active);
        dot.classList.toggle("w-6", active);
        dot.classList.toggle("bg-slate-600", !active);
        dot.classList.toggle("w-2", !active);
        dot.setAttribute("aria-current", active ? "true" : "false");
      });
    }
  }
}
