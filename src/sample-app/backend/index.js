// 示例后端：暴露 3000 端口，返回简单 JSON。
// 作为容器模式目录中各模式的部署目标示例（负载均衡 / 服务发现 / sidecar）。
const http = require("http");

const PORT = process.env.PORT || 3000;
const HOSTNAME = process.env.HOSTNAME || "unknown";

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(
    JSON.stringify({
      service: "sample-app",
      instance: HOSTNAME,
      message: "hello from container patterns catalog",
      time: new Date().toISOString(),
    })
  );
});

server.listen(PORT, () => {
  console.log(`sample-app listening on port ${PORT}`);
});
