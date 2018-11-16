const fs = require('fs');
const path = require('path');
const Validator = require('jsonschema').Validator;
const v = new Validator();

const ROOT_DIR = '/proxy/schemas';
const schemas = {}

if( !fs.existsSync(ROOT_DIR) ) {
  process.exit('Unable to find schemas director: '+ROOT_DIR);
}

function validate(schema, instance) {
  let schemaPath = path.join(ROOT_DIR, schema+'.json');
  if( !fs.existsSync(schemaPath) ) {
    throw new Error('Unknown schema: '+schema);
  }
  schema = JSON.parse(fs.readFileSync(schemaPath, 'utf-8'));
  v.validate(instance, schema, {throwError: true});
}

module.exports = validate;