const yargs = require('yargs');
const date = new Date();
const dateUTC = date.toUTCString();

const argv = yargs
  .option('port', {
    alias: 'p',
    description: 'The port on which the server listens',
    type: 'number',
    default: 80
  })
  .option('name', {
    alias: 'n',
    description: 'The name of the server owner',
    type: 'string',
    default: "Viktor Vodnev"
  })
  .argv;

const port = argv.port
const name = argv.name

console.log(`Date: ${dateUTC} | TCP Port: ${port} | Server owner: ${name}`)