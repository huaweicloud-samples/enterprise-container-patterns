// 定时任务示例：执行一次周期性工作后退出（CCE CronJob 调度）。
const fs = require("fs");

const run = () => {
  const line = `[${new Date().toISOString()}] periodic task executed\n`;
  fs.appendFileSync("/tmp/cron-task.log", line);
  console.log(line.trim());
  process.exit(0);
};

run();
