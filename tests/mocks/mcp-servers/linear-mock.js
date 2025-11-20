#!/usr/bin/env node

/**
 * Linear MCP Mock Server
 *
 * Simulates Linear API responses for testing without hitting real API.
 *
 * Features:
 * - Issue operations (create, read, update, delete)
 * - Label management
 * - State transitions
 * - Team and project operations
 * - Comment operations
 * - Document operations
 * - Error simulation
 * - Rate limiting simulation
 *
 * Usage:
 *   node linear-mock.js --port 3001 --fixtures ./fixtures/linear
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

class LinearMockServer {
  constructor(fixturesPath) {
    this.fixturesPath = fixturesPath;
    this.state = {
      issues: new Map(),
      labels: new Map(),
      states: new Map(),
      teams: new Map(),
      projects: new Map(),
      comments: new Map(),
      documents: new Map()
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
      // Load teams
      const teamsFile = path.join(this.fixturesPath, 'teams.json');
      if (fs.existsSync(teamsFile)) {
        const teams = JSON.parse(fs.readFileSync(teamsFile, 'utf8')).teams;
        teams.forEach(team => this.state.teams.set(team.id, team));
      }

      // Load projects
      const projectsFile = path.join(this.fixturesPath, 'projects.json');
      if (fs.existsSync(projectsFile)) {
        const projects = JSON.parse(fs.readFileSync(projectsFile, 'utf8')).projects;
        projects.forEach(project => this.state.projects.set(project.id, project));
      }

      // Load labels
      const labelsFile = path.join(this.fixturesPath, 'labels.json');
      if (fs.existsSync(labelsFile)) {
        const labels = JSON.parse(fs.readFileSync(labelsFile, 'utf8')).labels;
        labels.forEach(label => this.state.labels.set(label.id, label));
      }

      // Load states
      const statesFile = path.join(this.fixturesPath, 'states.json');
      if (fs.existsSync(statesFile)) {
        const states = JSON.parse(fs.readFileSync(statesFile, 'utf8')).states;
        states.forEach(state => this.state.states.set(state.id, state));
      }

      // Load issues
      const issuesFile = path.join(this.fixturesPath, 'issues.json');
      if (fs.existsSync(issuesFile)) {
        const issues = JSON.parse(fs.readFileSync(issuesFile, 'utf8')).issues;
        issues.forEach(issue => this.state.issues.set(issue.id, issue));
      }

      console.log('[LinearMock] Fixtures loaded successfully');
      console.log(`  Teams: ${this.state.teams.size}`);
      console.log(`  Projects: ${this.state.projects.size}`);
      console.log(`  Labels: ${this.state.labels.size}`);
      console.log(`  States: ${this.state.states.size}`);
      console.log(`  Issues: ${this.state.issues.size}`);
    } catch (error) {
      console.error('[LinearMock] Error loading fixtures:', error);
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
      // Team operations
      case 'linear_list_teams':
        return this.listTeams();
      case 'linear_get_team':
        return this.getTeam(params);

      // Project operations
      case 'linear_list_projects':
        return this.listProjects(params);
      case 'linear_get_project':
        return this.getProject(params);

      // Issue operations
      case 'linear_create_issue':
        return this.createIssue(params);
      case 'linear_get_issue':
        return this.getIssue(params);
      case 'linear_update_issue':
        return this.updateIssue(params);
      case 'linear_delete_issue':
        return this.deleteIssue(params);
      case 'linear_search_issues':
        return this.searchIssues(params);

      // Label operations
      case 'linear_create_label':
        return this.createLabel(params);
      case 'linear_get_label':
        return this.getLabel(params);
      case 'linear_list_labels':
        return this.listLabels(params);
      case 'linear_update_label':
        return this.updateLabel(params);
      case 'linear_delete_label':
        return this.deleteLabel(params);

      // State operations
      case 'linear_list_states':
        return this.listStates(params);
      case 'linear_get_state':
        return this.getState(params);

      // Comment operations
      case 'linear_create_comment':
        return this.createComment(params);
      case 'linear_list_comments':
        return this.listComments(params);

      // Document operations
      case 'linear_create_document':
        return this.createDocument(params);
      case 'linear_get_document':
        return this.getDocument(params);
      case 'linear_update_document':
        return this.updateDocument(params);

      default:
        throw {
          code: 'METHOD_NOT_FOUND',
          message: `Unknown method: ${method}`
        };
    }
  }

  // Team operations
  listTeams() {
    return {
      teams: Array.from(this.state.teams.values())
    };
  }

  getTeam(params) {
    const team = this.state.teams.get(params.teamId);
    if (!team) {
      throw {
        code: 'NOT_FOUND',
        message: `Team not found: ${params.teamId}`
      };
    }
    return team;
  }

  // Project operations
  listProjects(params) {
    let projects = Array.from(this.state.projects.values());

    if (params.teamId) {
      projects = projects.filter(p => p.teamId === params.teamId);
    }

    return { projects };
  }

  getProject(params) {
    const project = this.state.projects.get(params.projectId);
    if (!project) {
      throw {
        code: 'NOT_FOUND',
        message: `Project not found: ${params.projectId}`
      };
    }
    return project;
  }

  // Issue operations
  createIssue(params) {
    const issueId = `${params.teamId.split('-')[1]}-${this.state.issues.size + 1}`;
    const issue = {
      id: issueId,
      identifier: issueId,
      title: params.title,
      description: params.description || '',
      stateId: params.stateId || this.getDefaultStateId(params.teamId),
      teamId: params.teamId,
      projectId: params.projectId || null,
      labelIds: params.labelIds || [],
      assigneeId: params.assigneeId || null,
      priority: params.priority || 0,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      url: `https://linear.app/test/issue/${issueId}`
    };

    this.state.issues.set(issue.id, issue);
    return issue;
  }

  getIssue(params) {
    const issue = this.state.issues.get(params.issueId);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueId}`,
        suggestions: [
          'Verify the issue ID is correct',
          'Check if the issue was deleted',
          `Available issues: ${Array.from(this.state.issues.keys()).join(', ')}`
        ]
      };
    }
    return issue;
  }

  updateIssue(params) {
    const issue = this.state.issues.get(params.issueId);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueId}`
      };
    }

    // Update fields
    const updatedIssue = {
      ...issue,
      ...params.updates,
      updatedAt: new Date().toISOString()
    };

    this.state.issues.set(params.issueId, updatedIssue);
    return updatedIssue;
  }

  deleteIssue(params) {
    const issue = this.state.issues.get(params.issueId);
    if (!issue) {
      throw {
        code: 'NOT_FOUND',
        message: `Issue not found: ${params.issueId}`
      };
    }

    this.state.issues.delete(params.issueId);
    return { success: true };
  }

  searchIssues(params) {
    let issues = Array.from(this.state.issues.values());

    // Filter by team
    if (params.teamId) {
      issues = issues.filter(i => i.teamId === params.teamId);
    }

    // Filter by project
    if (params.projectId) {
      issues = issues.filter(i => i.projectId === params.projectId);
    }

    // Filter by state
    if (params.stateId) {
      issues = issues.filter(i => i.stateId === params.stateId);
    }

    // Filter by labels
    if (params.labelIds && params.labelIds.length > 0) {
      issues = issues.filter(i =>
        params.labelIds.some(labelId => i.labelIds.includes(labelId))
      );
    }

    // Search by title/description
    if (params.query) {
      const query = params.query.toLowerCase();
      issues = issues.filter(i =>
        i.title.toLowerCase().includes(query) ||
        i.description.toLowerCase().includes(query)
      );
    }

    return {
      issues,
      count: issues.length
    };
  }

  // Label operations
  createLabel(params) {
    const labelId = `label-${this.state.labels.size + 1}`;
    const label = {
      id: labelId,
      name: params.name,
      color: params.color || '#95a2b3',
      description: params.description || '',
      teamId: params.teamId,
      createdAt: new Date().toISOString()
    };

    // Check for duplicate names (case-insensitive)
    const existingLabel = Array.from(this.state.labels.values()).find(
      l => l.name.toLowerCase() === params.name.toLowerCase() && l.teamId === params.teamId
    );

    if (existingLabel) {
      return existingLabel; // Return existing label (idempotent)
    }

    this.state.labels.set(label.id, label);
    return label;
  }

  getLabel(params) {
    const label = this.state.labels.get(params.labelId);
    if (!label) {
      throw {
        code: 'NOT_FOUND',
        message: `Label not found: ${params.labelId}`
      };
    }
    return label;
  }

  listLabels(params) {
    let labels = Array.from(this.state.labels.values());

    if (params.teamId) {
      labels = labels.filter(l => l.teamId === params.teamId);
    }

    return { labels };
  }

  updateLabel(params) {
    const label = this.state.labels.get(params.labelId);
    if (!label) {
      throw {
        code: 'NOT_FOUND',
        message: `Label not found: ${params.labelId}`
      };
    }

    const updatedLabel = {
      ...label,
      ...params.updates
    };

    this.state.labels.set(params.labelId, updatedLabel);
    return updatedLabel;
  }

  deleteLabel(params) {
    const label = this.state.labels.get(params.labelId);
    if (!label) {
      throw {
        code: 'NOT_FOUND',
        message: `Label not found: ${params.labelId}`
      };
    }

    this.state.labels.delete(params.labelId);
    return { success: true };
  }

  // State operations
  listStates(params) {
    let states = Array.from(this.state.states.values());

    if (params.teamId) {
      states = states.filter(s => s.teamId === params.teamId);
    }

    return { states };
  }

  getState(params) {
    const state = this.state.states.get(params.stateId);
    if (!state) {
      throw {
        code: 'NOT_FOUND',
        message: `State not found: ${params.stateId}`,
        suggestions: [
          'Verify the state ID is correct',
          `Available states: ${Array.from(this.state.states.values()).map(s => s.name).join(', ')}`
        ]
      };
    }
    return state;
  }

  // Comment operations
  createComment(params) {
    const commentId = `comment-${this.state.comments.size + 1}`;
    const comment = {
      id: commentId,
      body: params.body,
      issueId: params.issueId,
      userId: params.userId || 'test-user',
      createdAt: new Date().toISOString()
    };

    this.state.comments.set(comment.id, comment);
    return comment;
  }

  listComments(params) {
    let comments = Array.from(this.state.comments.values());

    if (params.issueId) {
      comments = comments.filter(c => c.issueId === params.issueId);
    }

    return { comments };
  }

  // Document operations
  createDocument(params) {
    const documentId = `doc-${this.state.documents.size + 1}`;
    const document = {
      id: documentId,
      title: params.title,
      content: params.content || '',
      projectId: params.projectId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    this.state.documents.set(document.id, document);
    return document;
  }

  getDocument(params) {
    const document = this.state.documents.get(params.documentId);
    if (!document) {
      throw {
        code: 'NOT_FOUND',
        message: `Document not found: ${params.documentId}`
      };
    }
    return document;
  }

  updateDocument(params) {
    const document = this.state.documents.get(params.documentId);
    if (!document) {
      throw {
        code: 'NOT_FOUND',
        message: `Document not found: ${params.documentId}`
      };
    }

    const updatedDocument = {
      ...document,
      ...params.updates,
      updatedAt: new Date().toISOString()
    };

    this.state.documents.set(params.documentId, updatedDocument);
    return updatedDocument;
  }

  // Helper methods
  getDefaultStateId(teamId) {
    const states = Array.from(this.state.states.values()).filter(
      s => s.teamId === teamId && s.type === 'unstarted'
    );
    return states.length > 0 ? states[0].id : null;
  }

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
      labels: new Map(),
      states: new Map(),
      teams: new Map(),
      projects: new Map(),
      comments: new Map(),
      documents: new Map()
    };
    this.loadFixtures();
  }

  getStats() {
    return {
      requestCount: this.requestCount,
      issues: this.state.issues.size,
      labels: this.state.labels.size,
      states: this.state.states.size,
      teams: this.state.teams.size,
      projects: this.state.projects.size,
      comments: this.state.comments.size,
      documents: this.state.documents.size
    };
  }
}

// HTTP server wrapper
function createServer(mockServer, port = 3001) {
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
    console.log(`[LinearMock] Server listening on http://localhost:${port}`);
  });

  return server;
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const port = args.includes('--port') ? parseInt(args[args.indexOf('--port') + 1]) : 3001;
  const fixturesPath = args.includes('--fixtures')
    ? args[args.indexOf('--fixtures') + 1]
    : path.join(__dirname, '../fixtures/linear');

  const mockServer = new LinearMockServer(fixturesPath);
  createServer(mockServer, port);
}

module.exports = { LinearMockServer, createServer };
