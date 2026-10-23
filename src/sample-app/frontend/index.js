// 示例前端：暴露 3000 端口，调用后端（由 NODEJS_URL 指定）聚合结果后返回。
const http = require("http");

const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.NODEJS_URL || "http://127.0.0.1:3000";

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    http
      .get(url, (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => resolve(data));
      })
      .on("error", reject);
  });
}

const server = http.createServer(async (req, res) => {
  try {
    const upstream = await fetchJson(BACKEND_URL);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        service: "sample-frontend",
        backend: BACKEND_URL,
        backendResponse: JSON.parse(upstream),
        time: new Date().toISOString(),
      })
    );
  } catch (e) {
    res.writeHead(502, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ error: String(e) }));
  }
});

server.listen(PORT, () => {
  console.log(`sample-frontend listening on ${PORT}, backend=${BACKEND_URL}`);
});
