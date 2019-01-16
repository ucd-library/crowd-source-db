const httpProxy = require('http-proxy');
const streamify = require('stream-array');
const parse = require('csv-parse/lib/sync')
const request = require('request');
const SchemaError = require('./SchemaError');

let CLOUD_FUNCTION_HOST = process.env.CLOUD_FUNCTION_HOST;
if( !CLOUD_FUNCTION_HOST ) {
  console.error('environmental variable CLOUD_FUNCTION_HOST not set');
  process.exit(-1);
}

const proxy = httpProxy.createProxyServer({
  ignorePath : true
});

class SchemaProxy {

  constructor() {
    this.pgrHost = 'http://pgr:3000';
    this.handleMethods = ['POST', 'PUT', 'PATCH'];
    this.tables = ['crowd_inputs'];

    proxy.on('proxyReq', function(proxyReq, req, res, options) {
      // pipe post body
      if ( req.body && req.proxyInspected ) {
        let bodyData = req.body;
        if( typeof bodyData !== 'string' ) {
          bodyData = JSON.stringify(bodyData);
        }
        if( bodyData !== '{}' ) {
          proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
          proxyReq.write(bodyData);
        }
      }
    });
  }

  async middleware(req, res) {
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
        await this.validate(item);

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

    req.proxyInspected = true;
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
    console.log('Proxying request:', this.pgrHost+req.originalUrl);
    let options = {
      target : this.pgrHost+req.originalUrl,
    };
    proxy.web(req, res, options);
  }

  /**
   * @method validate
   * @description given a crowdInput
   */
  async validate(crowdInput) {
    let response = await this._request(
      `${CLOUD_FUNCTION_HOST}/api/crowd-input/validate`,
      {
        method : 'POST',
        body : JSON.stringify(crowdInput),
        headers : {
          'content-type' : 'application/json'
        }
      }
    );

    let body = JSON.parse(response.body);
    if( body.error ) throw new SchemaError(body.message, crowdInput);
  }

  _request(uri, options) {
    return new Promise((resolve, reject) => {
      request(uri, options, (error, response) => {
        if( error ) reject(error);
        else resolve(response);
      });
    });
  }

}


module.exports = new SchemaProxy();