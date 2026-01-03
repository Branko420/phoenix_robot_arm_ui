// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// 1. DEFINE HOOKS FIRST
let Hooks = {}

// (Optional) Hook for manual syncing if needed, though the server-side fix is better.
Hooks.JointSync = {
  updated() {
    let val = this.el.dataset.angle;
    let slider = this.el.querySelector('input[type="range"]');
    let number = this.el.querySelector('input[type="number"]');
    
    if (slider) slider.value = val;
    if (number) number.value = val;
  }
}

// 2. CONFIGURE LIVE SOCKET (Pass 'hooks: Hooks' here)
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks // <--- THIS WAS MISSING
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// Add flash message auto-close logic
window.addEventListener("phx:flash_expire", (e) => {
  setTimeout(() => {
    const flash = document.querySelector(".phx-flash");
    if (flash) flash.style.display = "none";
  }, 5000);
});

// Auto-hide any flash message that appears on page load
window.addEventListener("phx:page-loading-stop", _info => {
  setTimeout(() => {
    document.querySelectorAll(".flash-container").forEach(el => {
       el.classList.add("opacity-0", "transition-opacity", "duration-1000");
       setTimeout(() => el.remove(), 1000);
    });
  }, 3000);
})

// expose liveSocket on window for web console debug logs and latency simulation:
window.liveSocket = liveSocket