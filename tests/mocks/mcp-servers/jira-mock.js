#!/usr/bin/env node

/**
 * Jira MCP Mock Server
 *
 * Simulates Jira API responses for testing without hitting real API.
 *
 * Features:
 * - Issue operations (create, read, update, transition, delete)
 * - Project operations
 * - Issue type metadata
 * - Transition management
 * - Comment operations
 * - User lookup
 * - Error simulation
 * - Rate limiting simulation
 *
 * Usage:
 *   node jira-mock.js --port 3002 --fixtures ./fixtures/jira
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

class JiraMockServer {
  constructor(fixturesPath) {
    this.fixturesPath = fixturesPath;
    this.state = {
      issues: new Map(),
      projects: new Map(),
      issueTypes: new Map(),
      transitions: new Map(),
      comments: new Map(),
      users: new Map(),
      priorities: new Map(),
      statuses: new Map()
    };
    this.requestCount = 0;
    this.rateLimitThreshold = 100; // requests per minute
    this.errorSimulation = {
      enabled: false,
      probability: 0, // 0-1
      types: ['network', 'rate_limit', 'permission_denied', 'not_found']
    };

    this.loadFixtures();
  }

  loadFixtures() {
    try {
      // Load projects
      const projectsFile = path.join(this.fixturesPath, 'projects.json');
      if (fs.existsSync(projectsFile)) {
        const projects = JSON.parse(fs.readFileSync(projectsFile, 'utf8')).projects;
        projects.forEach(project => this.state.projects.set(project.key, project));
      }

      // Load issue types
      const issueTypesFile = path.join(this.fixturesPath, 'issue-types.json');
      if (fs.existsSync(issueTypesFile)) {
        const issueTypes = JSON.parse(fs.readFileSync(issueTypesFile, 'utf8')).issueTypes;
        issueTypes.forEach(type => this.state.issueTypes.set(type.id, type));
      }

      // Load priorities
      const prioritiesFile = path.join(this.fixturesPath, 'priorities.json');
      if (fs.existsSync(prioritiesFile)) {
        const priorities = JSON.parse(fs.readFileSync(prioritiesFile, 'utf8')).priorities;
        priorities.forEach(priority => this.state.priorities.set(priority.id, priority));
      }

      // Load statuses
      const statusesFile = path.join(this.fixturesPath, 'statuses.json');
      if (fs.existsSync(statusesFile)) {
        const statuses = JSON.parse(fs.readFileSync(statusesFile, 'utf8')).statuses;
        statuses.forEach(status => this.state.statuses.set(status.id, status));
      }

      // Load issues
      const issuesFile = path.join(this.fixturesPath, 'issues.json');
      if (fs.existsSync(issuesFile)) {
        const issues = JSON.parse(fs.readFileSync(issuesFile, 'utf8')).issues;
        issues.forEach(issue => this.state.issues.set(issue.key, issue));
      }

      // Load users
      const usersFile = path.join(this.fixturesPath, 'users.json');
      if (fs.existsSync(usersFile)) {
        const users = JSON.parse(fs.readFileSync(usersFile, 'utf8')).users;
        users.forEach(user => this.state.users.set(user.accountId, user));
      }

      console.log('[JiraMock] Fixtures loaded successfully');
      console.log(`  Projects: ${this.state.projects.size}`);
      console.log(`  Issue Types: ${this.state.issueTypes.size}`);
      console.log(`  Priorities: ${this.state.priorities.size}`);
      console.log(`  Statuses: ${this.state.statuses.size}`);
      console.log(`  Issues: ${this.state.issues.size}`);
      console.log(`  Users: ${this.state.users.size}`);
    } catch (error) {
      console.error('[JiraMock] Error loading fixtures:', error);
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
      // Issue operations
      case 'jira_create_issue':
        return this.createIssue(params);
      case 'jira_get_issue':
        return this.getIssue(params);
      case 'jira_update_issue':
        return this.updateIssue(params);
      case 'jira_delete_issue':
        return this.deleteIssue(params);
      case 'jira_search_issues':
        return this.searchIssues(params);

      // Transition operations
      case 'jira_get_transitions':
        return this.getTransitions(params);
      case 'jira_transition_issue':
        return this.transitionIssue(params);

      // Comment operations
      case 'jira_add_comment':
        return this.addComment(params);
      case 'jira_get_comments':
        return this.getComments(params);

      // Project operations
      case 'jira_list_projects':
        return this.listProjects(params);
      case 'jira_get_project':
        return this.getProject(params);
      case 'jira_get_project_issue_types':
        return this.getProjectIssueTypes(params);

      // User operations
      case 'jira_lookup_user':
        return this.lookupUser(params);

      default:
        throw {
          code: 'METHOD_NOT_FOUND',
          message: `Unknown method: ${method}`
        };
    }
  }

  // Issue operations
  createIssue(params) {
    const project = this.state.projects.get(params.projectKey);
    if (!project) {
      throw {
        code: 'NOT_FOUND',
        message: `Project not found: ${params.projectKey}`
      };
    }

    const issueNumber = this.state.issues.size + 1;
    const issueKey = `${params.projectKey}-${issueNumber}`;

    const issue = {
      id: `issue-${Date.now()}`,
      key: issueKey,
      fields: {
        summary: params.summary,
        description: params.description || '',
        issuetype: params.issueType || { name: 'Task' },
        project: project,
        priority: params.priority || { id: '3', name: 'Medium' },
        status: { id: '10000', name: 'To Do' },
        assignee: params.assignee || null,
        reporter: params.reporter || { accountId: 'test-user' },
        created: new Date().toISOString(),
        updated: new Date().toISOString()
      },
      self: `https://jira.test.com/rest/api/2/issue/${issueKey}`
    };

    this.state.issues.set(issue.key, issue);
    return issue;
  }

  getIssue(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`,
        suggestions: [
          'Verify the issue key is correct',
          'Check if the issue was deleted',
          `Available issues: ${Array.from(this.state.issues.keys()).join(', ')}`
        ]
      };
    }
    return issue;
  }

  updateIssue(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`
      };
    }

    // Update fields
    const updatedIssue = {
      ...issue,
      fields: {
        ...issue.fields,
        ...params.fields,
        updated: new Date().toISOString()
      }
    };

    this.state.issues.set(params.issueIdOrKey, updatedIssue);
    return updatedIssue;
  }

  deleteIssue(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`
      };
    }

    this.state.issues.delete(params.issueIdOrKey);
    return { success: true };
  }

  searchIssues(params) {
    let issues = Array.from(this.state.issues.values());

    // Apply JQL filter (simplified implementation)
    if (params.jql) {
      const jql = params.jql.toLowerCase();

      // Parse simple JQL queries
      if (jql.includes('project =')) {
        const projectKey = jql.match(/project = (\w+)/)?.[1]?.toUpperCase();
        if (projectKey) {
          issues = issues.filter(i => i.fields.project.key === projectKey);
        }
      }

      if (jql.includes('status =')) {
        const status = jql.match(/status = "([^"]+)"/)?.[1];
        if (status) {
          issues = issues.filter(i => i.fields.status.name === status);
        }
      }

      if (jql.includes('assignee =')) {
        const assignee = jql.match(/assignee = (\w+)/)?.[1];
        if (assignee === 'currentUser()') {
          issues = issues.filter(i => i.fields.assignee?.accountId === 'test-user');
        }
      }
    }

    const maxResults = params.maxResults || 50;
    const startAt = params.startAt || 0;
    const paginatedIssues = issues.slice(startAt, startAt + maxResults);

    return {
      issues: paginatedIssues,
      total: issues.length,
      startAt,
      maxResults
    };
  }

  // Transition operations
  getTransitions(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`
      };
    }

    // Return available transitions based on current status
    const transitions = [
      { id: '11', name: 'To Do', to: { id: '10000', name: 'To Do' } },
      { id: '21', name: 'In Progress', to: { id: '10001', name: 'In Progress' } },
      { id: '31', name: 'Done', to: { id: '10002', name: 'Done' } }
    ];

    return { transitions };
  }

  transitionIssue(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`
      };
    }

    // Update status based on transition
    const updatedIssue = {
      ...issue,
      fields: {
        ...issue.fields,
        status: params.transition.to || params.transition,
        updated: new Date().toISOString()
      }
    };

    this.state.issues.set(params.issueIdOrKey, updatedIssue);
    return { success: true };
  }

  // Comment operations
  addComment(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`
      };
    }

    const commentId = `comment-${Date.now()}`;
    const comment = {
      id: commentId,
      body: params.body,
      author: { accountId: 'test-user', displayName: 'Test User' },
      created: new Date().toISOString(),
      updated: new Date().toISOString()
    };

    // Store comment associated with issue
    const issueComments = this.state.comments.get(params.issueIdOrKey) || [];
    issueComments.push(comment);
    this.state.comments.set(params.issueIdOrKey, issueComments);

    return comment;
  }

  getComments(params) {
    const issue = this.state.issues.get(params.issueIdOrKey);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueIdOrKey}`
      };
    }

    const comments = this.state.comments.get(params.issueIdOrKey) || [];
    return { comments };
  }

  // Project operations
  listProjects(params) {
    let projects = Array.from(this.state.projects.values());

    // Filter by action permission (view, browse, edit, create)
    if (params.action) {
      // In mock, assume user has all permissions
      projects = projects;
    }

    return { projects };
  }

  getProject(params) {
    const project = this.state.projects.get(params.projectKey);
    if (!project) {
      throw {
        code: 'NOT_FOUND',
        message: `Project not found: ${params.projectKey}`
      };
    }
    return project;
  }

  getProjectIssueTypes(params) {
    const project = this.state.projects.get(params.projectKey);
    if (!project) {
      throw {
        code: 'NOT_FOUND',
        message: `Project not found: ${params.projectKey}`
      };
    }

    const issueTypes = Array.from(this.state.issueTypes.values());
    return {
      issueTypes,
      project
    };
  }

  // User operations
  lookupUser(params) {
    let users = Array.from(this.state.users.values());

    if (params.query) {
      const query = params.query.toLowerCase();
      users = users.filter(u =>
        u.displayName.toLowerCase().includes(query) ||
        u.emailAddress.toLowerCase().includes(query)
      );
    }

    return { users };
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
      issues: new Map(),
      projects: new Map(),
      issueTypes: new Map(),
      transitions: new Map(),
      comments: new Map(),
      users: new Map(),
      priorities: new Map(),
      statuses: new Map()
    };
    this.loadFixtures();
  }

  getStats() {
    return {
      requestCount: this.requestCount,
      issues: this.state.issues.size,
      projects: this.state.projects.size,
      issueTypes: this.state.issueTypes.size,
      comments: this.state.comments.size,
      users: this.state.users.size
    };
  }
}

// HTTP server wrapper
function createServer(mockServer, port = 3002) {
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
    console.log(`[JiraMock] Server listening on http://localhost:${port}`);
  });

  return server;
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const port = args.includes('--port') ? parseInt(args[args.indexOf('--port') + 1]) : 3002;
  const fixturesPath = args.includes('--fixtures')
    ? args[args.indexOf('--fixtures') + 1]
    : path.join(__dirname, '../fixtures/jira');

  const mockServer = new JiraMockServer(fixturesPath);
  createServer(mockServer, port);
}

module.exports = { JiraMockServer, createServer };
