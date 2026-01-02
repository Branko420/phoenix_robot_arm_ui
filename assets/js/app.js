// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()
// Add this to assets/js/app.js
window.addEventListener("phx:flash_expire", (e) => {
  setTimeout(() => {
    // This finds the close button or just clears the flash area
    const flash = document.querySelector(".phx-flash");
    if (flash) flash.style.display = "none";
  }, 5000); // 5 seconds
});

// Auto-hide any flash message that appears
window.addEventListener("phx:page-loading-stop", _info => {
  setTimeout(() => {
    document.querySelectorAll(".flash-container").forEach(el => {
       el.classList.add("opacity-0", "transition-opacity", "duration-1000");
       setTimeout(() => el.remove(), 1000);
    });
  }, 3000);
})

let Hooks = {}

Hooks.JointSync = {
  updated() {
    // When the server updates the value, ensure both inputs match
    let val = this.el.dataset.angle;
    let slider = this.el.querySelector('input[type="range"]');
    let number = this.el.querySelector('input[type="number"]');
    
    if (slider) slider.value = val;
    if (number) number.value = val;
  }
}

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

