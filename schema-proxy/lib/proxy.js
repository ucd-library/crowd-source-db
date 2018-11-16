const httpProxy = require('http-proxy');
const parse = require('csv-parse/lib/sync')
const schemaValidator = require('./schema');
const SchemaError = require('./SchemaError');

const proxy = httpProxy.createProxyServer({
  ignorePath : true
});

class SchemaProxy {

  constructor() {
    this.pgrHost = 'http://pgr:3000';
    this.handleMethods = ['POST', 'PUT', 'PATCH'];
    this.tables = ['crowd_inputs']
  }

  middleware(req, res) {
    // check this is POST or PUT
    let method = req.method;
    if( this.handleMethods.indexOf(method) === -1  ) {
      return this.passthrough(req, res);
    }

    let table = req.path.replace(/\/$/, '').split('/');
    if( !table.length ) {
      return this.passthrough(req, res);
    }
    table = table.pop();

    // verify its a table we want to validate the data field
    if( this.tables.indexOf(table) === -1 ) {
      return this.passthrough(req, res);
    }

    try {
      let body = this.getJsonBody(req);
      for( let item of body ) {
        if( !item.data ) continue;
        this.validate(item.data);

        // a little manual validation
        if( table === 'crowd_inputs' ) {
          if( item.anonymous && !item.user_id ) {
            throw new SchemaError('Crowd input must be anonymous or provide a user_id', item);
          }
        }
      }
    } catch(e) {
      return res.status(400).json({
        error : true,
        type : 'SchemaError',
        message : e.message,
        data : e.data
      });
    }

    this.passthrough(req, res);
  }

  /**
   * @method getJsonBody
   * @description get body as array of json objects.  will parse JSON
   * or CSV
   * 
   * @param {Object} req express request object
   * 
   * @returns {Array} 
   */
  getJsonBody(req) {
    let contentType = req.get('content-type');
    let jsonBody = null;

    if( contentType.match('text/csv') ) {
      jsonBody = parse(req.body, {
        columns: true,
        skip_empty_lines: true
      })
    } else if( contentType.match('application/json') ) {
      jsonBody = JSON.parse(req.body);
      if( !Array.isArray(jsonBody) ) {
        jsonBody = [jsonBody];
      }
    } else {
      throw new Error('Bad content-type: '+contentType);
    }

    return jsonBody;
  }

  /**
   * @method passthrough
   * @description send the request to pgr
   * 
   * @param {*} req 
   * @param {*} res 
   */
  passthrough(req, res) {
    proxy.web(req, res, {
      target : this.pgrHost+req.originalUrl,
    });
  }

  /**
   * @method validate
   * @description given a mark
   */
  validate(data) {
    if( typeof data === 'String' ) {
      data = JSON.parse(data);
    }

    if( !data['@schema'] ) {
      throw new SchemaError('Data @schema not provided', data);
    }

    let schema = data['@schema'];
    delete data['@schema'];

    try {
      schemaValidator(schema, data);
    } catch(e) {
      throw new SchemaError(e.message, data);
    }

    // a little manual validation
    if( item.anonymous && !item.user_id ) {
      throw new SchemaError('')
    }
  }

}


module.exports = new SchemaProxy();