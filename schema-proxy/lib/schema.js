const { Pool, Client } = require('pg');
const Validator = require('jsonschema').Validator;

class SchemaValidator {

  constructor() {
    this.validator = new Validator();
    this.pgClient = new Pool({
      connectionString: 'postgresql://postgres:postgres@postgres:5432/postgres',
    });
    this.validate = this.validate.bind(this);
  }

  async _getSchema(appId='', schemaId='') {
    let res = await this.pgClient.query(
      'SELECT * from crowd_source.schemas where app_id = $1 and schema_id = $2',
      [appId, schemaId]
    );

    if( res.rows && res.rows.length ) {
      return res.rows[0].schema;
    }
    return null;
  }

  /**
   * @method validate
   * 
   * @param {String} appId 
   * @param {Object} data
   * 
   * @returns {Promise} resolves to boolean
   */
  async validate(appId='', data) {
    if( !data['@schema'] ) throw new Error('No schema defined for object');
    let schemaId = data['@schema'];
    delete data['@schema'];

    let schema = await this._getSchema(appId, schemaId);
    if( !schema ) {
      throw new Error('Unknown schema '+schemaId+' for app '+appId);
    }
    this.validator.validate(data, schema, {throwError: true});
  }

}

const sv = new SchemaValidator();
module.exports = sv.validate;