import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return [ "labels", "datasets" ]
  }

  async connect() {
    let Chart = (await import("chart.js/auto")).default
    this.chart = new Chart(this.element.getContext("2d"), {
      data: {
        labels: JSON.parse(this.labelsTarget.textContent),
        datasets: JSON.parse(this.datasetsTarget.textContent)
      }
    })
  }

  disconnect() {
    this.chart.destroy()
  }
}
