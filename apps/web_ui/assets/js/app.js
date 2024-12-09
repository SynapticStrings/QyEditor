// 如果你想要使用 Phoenix channcels ，请运行 `mix help phx.gen.channel`
// 并且取消下面这一行代码的注释。
// import "./user_socket.js"

// 你可以通过两种方式来导入依赖项。
//
// 最简单的一种是把代码放在 assets/vendor 里并且通过相对路径来导入：
//
//     import "../vendor/some-package.js"
//
// 或者是，你可以 `npm install some-package --prefix assets` 并且使用
// 包的名字来导入它们：
//
//     import "some-package"
//

// 导入 phoenix_html 来处理表单和按钮中的 method=PUT/DELETE 。
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

// 在表单提交以及 live 引导使用进度条
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// 如果页面有 LiveView 的话，建立连接
liveSocket.connect()

// 暴露 liveSocket 在窗口里，为了 web 控制台调试日志和延迟模拟：
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // 在浏览器会话期间启用
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

