import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Infinite scroll for the mobile overtime list (SPEC §3 "Paginação").
//
// The server renders a sentinel at the end of the list carrying the URL of
// the next page. When the sentinel enters the viewport we fetch that URL as
// a Turbo Stream; the response removes the spent sentinel and appends the
// next cards, plus a fresh sentinel when more pages remain. On the last page
// no sentinel is rendered, so there is nothing left to observe and the
// scrolling stops by itself.
//
// On desktop the whole list (sentinel included) is hidden with md:hidden,
// and display:none elements never intersect, so the observer stays idle.
export default class extends Controller {
  static targets = [ "sentinel" ]

  initialize() {
    this.loading = false
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.checkIntersection(entries),
      // Start fetching slightly before the sentinel is fully visible.
      { rootMargin: "300px" }
    )
    this.sentinelTargets.forEach((sentinel) => this.observer.observe(sentinel))
  }

  disconnect() {
    this.observer?.disconnect()
    this.observer = null
  }

  // A fresh sentinel arrives with each appended page.
  sentinelTargetConnected(sentinel) {
    this.observer?.observe(sentinel)
  }

  sentinelTargetDisconnected(sentinel) {
    this.observer?.unobserve(sentinel)
  }

  async checkIntersection(entries) {
    if (!entries.some((entry) => entry.isIntersecting)) return
    if (this.loading) return

    const sentinel = this.sentinelTargets.at(-1)
    const url = sentinel?.dataset.nextUrl
    if (!url) return

    this.loading = true
    try {
      const response = await fetch(url, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      if (response.ok) {
        Turbo.renderStreamMessage(await response.text())
      } else {
        this.stop()
      }
    } catch {
      this.stop()
    } finally {
      this.loading = false
    }
  }

  stop() {
    this.observer?.disconnect()
  }
}
