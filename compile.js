const path = require("path");
const fs = require("fs");
const solc = require("solc");

const mediPath = path.resolve(__dirname, "contracts", "Medi.sol");
const source = fs.readFileSync(mediPath, "utf8");

module.exports = solc.compile(source, 1).contracts[":Medi"];


