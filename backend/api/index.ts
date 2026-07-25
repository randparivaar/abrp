import app from '../src/index.js';

export default async function handler(req: any, res: any) {
  try {
    // Construct absolute URL
    const protocol = req.headers['x-forwarded-proto'] || 'https';
    const host = req.headers['x-forwarded-host'] || req.headers.host || 'localhost';
    const url = `${protocol}://${host}${req.url}`;

    // Read request body safely for POST / PUT / PATCH
    let body: any = null;
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      if (req.body) {
        body = typeof req.body === 'string' || Buffer.isBuffer(req.body)
          ? req.body
          : JSON.stringify(req.body);
      } else {
        const chunks: Uint8Array[] = [];
        for await (const chunk of req) {
          chunks.push(chunk);
        }
        const buffer = Buffer.concat(chunks);
        if (buffer.length > 0) {
          body = buffer;
        }
      }
    }

    // Convert Node headers to standard Web Headers
    const headers = new Headers();
    for (const [key, value] of Object.entries(req.headers)) {
      if (value !== undefined) {
        if (Array.isArray(value)) {
          for (const v of value) {
            headers.append(key, v);
          }
        } else {
          headers.set(key, value as string);
        }
      }
    }

    // Construct Web Standard Request
    const webRequest = new Request(url, {
      method: req.method,
      headers,
      body,
    });

    // Execute Hono app
    const response = await app.fetch(webRequest);

    // Set response status code and headers
    res.statusCode = response.status;
    response.headers.forEach((value, key) => {
      res.setHeader(key, value);
    });

    // Send response body
    const arrayBuffer = await response.arrayBuffer();
    res.end(Buffer.from(arrayBuffer));
  } catch (error: any) {
    console.error('Vercel Serverless Handler Error:', error);
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ error: 'Internal Server Error', details: error?.message }));
  }
}
