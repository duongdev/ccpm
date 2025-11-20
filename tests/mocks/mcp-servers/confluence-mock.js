#!/usr/bin/env node

/**
 * Confluence MCP Mock Server
 *
 * Simulates Confluence API responses for testing without hitting real API.
 *
 * Features:
 * - Space operations
 * - Page operations (create, read, update, delete)
 * - Comment operations (footer and inline)
 * - Search operations (CQL)
 * - Content operations
 * - Error simulation
 * - Rate limiting simulation
 *
 * Usage:
 *   node confluence-mock.js --port 3004 --fixtures ./fixtures/confluence
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

class ConfluenceMockServer {
  constructor(fixturesPath) {
    this.fixturesPath = fixturesPath;
    this.state = {
      spaces: new Map(),
      pages: new Map(),
      comments: new Map(),
      users: new Map()
    };
    this.requestCount = 0;
    this.rateLimitThreshold = 100;
    this.errorSimulation = {
      enabled: false,
      probability: 0,
      types: ['network', 'rate_limit', 'permission_denied', 'not_found']
    };

    this.loadFixtures();
  }

  loadFixtures() {
    try {
      // Load spaces
      const spacesFile = path.join(this.fixturesPath, 'spaces.json');
      if (fs.existsSync(spacesFile)) {
        const spaces = JSON.parse(fs.readFileSync(spacesFile, 'utf8')).spaces;
        spaces.forEach(space => this.state.spaces.set(space.key, space));
      }

      // Load pages
      const pagesFile = path.join(this.fixturesPath, 'pages.json');
      if (fs.existsSync(pagesFile)) {
        const pages = JSON.parse(fs.readFileSync(pagesFile, 'utf8')).pages;
        pages.forEach(page => this.state.pages.set(page.id, page));
      }

      // Load users
      const usersFile = path.join(this.fixturesPath, 'users.json');
      if (fs.existsSync(usersFile)) {
        const users = JSON.parse(fs.readFileSync(usersFile, 'utf8')).users;
        users.forEach(user => this.state.users.set(user.accountId, user));
      }

      console.log('[ConfluenceMock] Fixtures loaded successfully');
      console.log(`  Spaces: ${this.state.spaces.size}`);
      console.log(`  Pages: ${this.state.pages.size}`);
      console.log(`  Users: ${this.state.users.size}`);
    } catch (error) {
      console.error('[ConfluenceMock] Error loading fixtures:', error);
    }
  }

  async handleRequest(method, params) {
    this.requestCount++;

    // Simulate rate limiting
    if (this.requestCount > this.rateLimitThreshold) {
      throw {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Rate limit exceeded. Please try again later.',
        retryAfter: 60
      };
    }

    // Simulate random errors if enabled
    if (this.errorSimulation.enabled && Math.random() < this.errorSimulation.probability) {
      const errorType = this.errorSimulation.types[
        Math.floor(Math.random() * this.errorSimulation.types.length)
      ];
      throw this.simulateError(errorType);
    }

    // Route to appropriate handler
    switch (method) {
      // Space operations
      case 'confluence_list_spaces':
        return this.listSpaces(params);
      case 'confluence_get_space':
        return this.getSpace(params);

      // Page operations
      case 'confluence_create_page':
        return this.createPage(params);
      case 'confluence_get_page':
        return this.getPage(params);
      case 'confluence_update_page':
        return this.updatePage(params);
      case 'confluence_delete_page':
        return this.deletePage(params);
      case 'confluence_list_pages':
        return this.listPages(params);

      // Comment operations
      case 'confluence_create_footer_comment':
        return this.createFooterComment(params);
      case 'confluence_create_inline_comment':
        return this.createInlineComment(params);
      case 'confluence_list_comments':
        return this.listComments(params);

      // Search operations
      case 'confluence_search':
        return this.search(params);

      default:
        throw {
          code: 'METHOD_NOT_FOUND',
          message: `Unknown method: ${method}`
        };
    }
  }

  // Space operations
  listSpaces(params) {
    let spaces = Array.from(this.state.spaces.values());

    if (params.type) {
      spaces = spaces.filter(s => s.type === params.type);
    }

    if (params.keys) {
      const keys = Array.isArray(params.keys) ? params.keys : [params.keys];
      spaces = spaces.filter(s => keys.includes(s.key));
    }

    return { spaces };
  }

  getSpace(params) {
    const space = this.state.spaces.get(params.spaceKey);
    if (!space) {
      throw {
        code: 'NOT_FOUND',
        message: `Space not found: ${params.spaceKey}`,
        suggestions: [
          'Verify the space key is correct',
          `Available spaces: ${Array.from(this.state.spaces.keys()).join(', ')}`
        ]
      };
    }
    return space;
  }

  // Page operations
  createPage(params) {
    const space = this.state.spaces.get(params.spaceKey);
    if (!space) {
      throw {
        code: 'NOT_FOUND',
        message: `Space not found: ${params.spaceKey}`
      };
    }

    const pageId = `page-${Date.now()}`;
    const page = {
      id: pageId,
      type: 'page',
      status: 'current',
      title: params.title,
      body: {
        storage: {
          value: params.content || '',
          representation: 'storage'
        }
      },
      space: {
        key: params.spaceKey,
        name: space.name
      },
      version: {
        number: 1,
        message: 'Initial version'
      },
      createdBy: {
        accountId: 'test-user',
        displayName: 'Test User'
      },
      createdDate: new Date().toISOString(),
      _links: {
        webui: `/spaces/${params.spaceKey}/pages/${pageId}`,
        self: `https://confluence.test.com/rest/api/content/${pageId}`
      }
    };

    if (params.parentId) {
      const parent = this.state.pages.get(params.parentId);
      if (!parent) {
        throw {
          code: 'NOT_FOUND',
          message: `Parent page not found: ${params.parentId}`
        };
      }
      page.ancestors = [{ id: params.parentId }];
    }

    this.state.pages.set(page.id, page);
    return page;
  }

  getPage(params) {
    const page = this.state.pages.get(params.pageId);
    if (!page) {
      throw {
        code: 'NOT_FOUND',
        message: `Page not found: ${params.pageId}`,
        suggestions: [
          'Verify the page ID is correct',
          'Check if the page was deleted',
          `Available pages: ${Array.from(this.state.pages.keys()).join(', ')}`
        ]
      };
    }
    return page;
  }

  updatePage(params) {
    const page = this.state.pages.get(params.pageId);
    if (!page) {
      throw {
        code: 'NOT_FOUND',
        message: `Page not found: ${params.pageId}`
      };
    }

    const updatedPage = {
      ...page,
      title: params.title || page.title,
      body: params.content ? {
        storage: {
          value: params.content,
          representation: 'storage'
        }
      } : page.body,
      version: {
        number: page.version.number + 1,
        message: params.versionMessage || 'Updated'
      },
      lastModified: new Date().toISOString()
    };

    this.state.pages.set(params.pageId, updatedPage);
    return updatedPage;
  }

  deletePage(params) {
    const page = this.state.pages.get(params.pageId);
    if (!page) {
      throw {
        code: 'NOT_FOUND',
        message: `Page not found: ${params.pageId}`
      };
    }

    this.state.pages.delete(params.pageId);
    return { success: true };
  }

  listPages(params) {
    let pages = Array.from(this.state.pages.values());

    if (params.spaceKey) {
      pages = pages.filter(p => p.space.key === params.spaceKey);
    }

    if (params.title) {
      pages = pages.filter(p => p.title.toLowerCase().includes(params.title.toLowerCase()));
    }

    if (params.status) {
      pages = pages.filter(p => p.status === params.status);
    }

    return { pages };
  }

  // Comment operations
  createFooterComment(params) {
    const page = this.state.pages.get(params.pageId);
    if (!page) {
      throw {
        code: 'NOT_FOUND',
        message: `Page not found: ${params.pageId}`
      };
    }

    const commentId = `comment-${Date.now()}`;
    const comment = {
      id: commentId,
      type: 'comment',
      body: {
        storage: {
          value: params.body,
          representation: 'storage'
        }
      },
      container: {
        id: params.pageId,
        type: 'page'
      },
      createdBy: {
        accountId: 'test-user',
        displayName: 'Test User'
      },
      createdDate: new Date().toISOString(),
      _links: {
        self: `https://confluence.test.com/rest/api/content/${commentId}`
      }
    };

    const pageComments = this.state.comments.get(params.pageId) || [];
    pageComments.push(comment);
    this.state.comments.set(params.pageId, pageComments);

    return comment;
  }

  createInlineComment(params) {
    const page = this.state.pages.get(params.pageId);
    if (!page) {
      throw {
        code: 'NOT_FOUND',
        message: `Page not found: ${params.pageId}`
      };
    }

    const commentId = `inline-comment-${Date.now()}`;
    const comment = {
      id: commentId,
      type: 'inline-comment',
      body: {
        storage: {
          value: params.body,
          representation: 'storage'
        }
      },
      container: {
        id: params.pageId,
        type: 'page'
      },
      inlineProperties: params.inlineCommentProperties || {},
      createdBy: {
        accountId: 'test-user',
        displayName: 'Test User'
      },
      createdDate: new Date().toISOString(),
      _links: {
        self: `https://confluence.test.com/rest/api/content/${commentId}`
      }
    };

    const pageComments = this.state.comments.get(params.pageId) || [];
    pageComments.push(comment);
    this.state.comments.set(params.pageId, pageComments);

    return comment;
  }

  listComments(params) {
    const comments = this.state.comments.get(params.pageId) || [];
    return { comments };
  }

  // Search operations
  search(params) {
    let results = [];

    // Search pages by title and content
    const pages = Array.from(this.state.pages.values());
    const query = params.query.toLowerCase();

    pages.forEach(page => {
      const titleMatch = page.title.toLowerCase().includes(query);
      const contentMatch = page.body?.storage?.value?.toLowerCase().includes(query);

      if (titleMatch || contentMatch) {
        results.push({
          ...page,
          excerpt: this.generateExcerpt(page.body?.storage?.value, query)
        });
      }
    });

    // Apply CQL filters if provided
    if (params.cql) {
      results = this.applyCQLFilter(results, params.cql);
    }

    return {
      results,
      size: results.length
    };
  }

  applyCQLFilter(results, cql) {
    const cqlLower = cql.toLowerCase();

    // Simple CQL parsing (can be extended)
    if (cqlLower.includes('type = page')) {
      results = results.filter(r => r.type === 'page');
    }

    if (cqlLower.includes('space =')) {
      const spaceKey = cql.match(/space = (\w+)/i)?.[1];
      if (spaceKey) {
        results = results.filter(r => r.space?.key === spaceKey);
      }
    }

    return results;
  }

  generateExcerpt(content, query, length = 200) {
    if (!content) return '';

    const index = content.toLowerCase().indexOf(query.toLowerCase());
    if (index === -1) return content.substring(0, length) + '...';

    const start = Math.max(0, index - 50);
    const end = Math.min(content.length, index + query.length + 150);
    return '...' + content.substring(start, end) + '...';
  }

  // Helper methods
  simulateError(type) {
    const errors = {
      network: {
        code: 'NETWORK_ERROR',
        message: 'Network connection failed'
      },
      rate_limit: {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Rate limit exceeded',
        retryAfter: 60
      },
      permission_denied: {
        code: 'PERMISSION_DENIED',
        message: 'Insufficient permissions'
      },
      not_found: {
        code: 'NOT_FOUND',
        message: 'Resource not found'
      }
    };
    return errors[type] || errors.network;
  }

  // Server state management
  reset() {
    this.state = {
      spaces: new Map(),
      pages: new Map(),
      comments: new Map(),
      users: new Map()
    };
    this.loadFixtures();
  }

  getStats() {
    return {
      requestCount: this.requestCount,
      spaces: this.state.spaces.size,
      pages: this.state.pages.size,
      comments: this.state.comments.size,
      users: this.state.users.size
    };
  }
}

// HTTP server wrapper
function createServer(mockServer, port = 3004) {
  const server = http.createServer(async (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');

    if (req.method === 'POST') {
      let body = '';
      req.on('data', chunk => body += chunk);
      req.on('end', async () => {
        try {
          const { method, params } = JSON.parse(body);
          const result = await mockServer.handleRequest(method, params);
          res.writeHead(200);
          res.end(JSON.stringify({ result }));
        } catch (error) {
          res.writeHead(error.code === 'NOT_FOUND' ? 404 : 500);
          res.end(JSON.stringify({ error }));
        }
      });
    } else if (req.method === 'GET' && req.url === '/stats') {
      res.writeHead(200);
      res.end(JSON.stringify(mockServer.getStats()));
    } else if (req.method === 'POST' && req.url === '/reset') {
      mockServer.reset();
      res.writeHead(200);
      res.end(JSON.stringify({ success: true }));
    } else {
      res.writeHead(404);
      res.end(JSON.stringify({ error: 'Not found' }));
    }
  });

  server.listen(port, () => {
    console.log(`[ConfluenceMock] Server listening on http://localhost:${port}`);
  });

  return server;
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const port = args.includes('--port') ? parseInt(args[args.indexOf('--port') + 1]) : 3004;
  const fixturesPath = args.includes('--fixtures')
    ? args[args.indexOf('--fixtures') + 1]
    : path.join(__dirname, '../fixtures/confluence');

  const mockServer = new ConfluenceMockServer(fixturesPath);
  createServer(mockServer, port);
}

module.exports = { ConfluenceMockServer, createServer };
