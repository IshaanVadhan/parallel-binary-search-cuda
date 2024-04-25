const express = require("express");
const bodyParser = require("body-parser");
const { exec } = require("child_process");

const app = express();
const port = 3000;

app.set("view engine", "ejs");

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.get("/", (req, res) => {
  res.sendFile(__dirname + "/index.html");
});

app.post("/compute", (req, res) => {
  const size = req.body.size;
  const key = req.body.key;
  const arr = req.body.arr.split(",").map(Number); // Assuming arr is a comma-separated string of numbers

  const command = `search.exe ${size} ${key} ${arr.join(" ")}`;

  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`exec error: ${error}`);
      res.send({ error: "An error occurred." });
      return;
    }

    const resultData = parseResult(stdout); // Parse the result into a JSON object
    res.render("result", { resultData: resultData });
  });
});

function parseResult(stdout) {
  return JSON.parse(stdout)?.result;
}

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
