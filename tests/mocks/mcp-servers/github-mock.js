#!/usr/bin/env node

/**
 * GitHub MCP Mock Server
 *
 * Simulates GitHub API responses for testing without hitting real API.
 *
 * Features:
 * - Repository operations
 * - Pull request operations (create, read, update, merge)
 * - Commit operations
 * - Branch operations
 * - Issue operations
 * - Comment operations
 * - Review operations
 * - Error simulation
 * - Rate limiting simulation
 *
 * Usage:
 *   node github-mock.js --port 3003 --fixtures ./fixtures/github
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

class GitHubMockServer {
  constructor(fixturesPath) {
    this.fixturesPath = fixturesPath;
    this.state = {
      repositories: new Map(),
      pullRequests: new Map(),
      commits: new Map(),
      branches: new Map(),
      issues: new Map(),
      comments: new Map(),
      reviews: new Map()
    };
    this.requestCount = 0;
    this.rateLimitThreshold = 5000; // GitHub has high rate limits
    this.errorSimulation = {
      enabled: false,
      probability: 0,
      types: ['network', 'rate_limit', 'permission_denied', 'not_found']
    };

    this.loadFixtures();
  }

  loadFixtures() {
    try {
      // Load repositories
      const reposFile = path.join(this.fixturesPath, 'repositories.json');
      if (fs.existsSync(reposFile)) {
        const repos = JSON.parse(fs.readFileSync(reposFile, 'utf8')).repositories;
        repos.forEach(repo => {
          const key = `${repo.owner.login}/${repo.name}`;
          this.state.repositories.set(key, repo);
        });
      }

      // Load pull requests
      const prsFile = path.join(this.fixturesPath, 'pull-requests.json');
      if (fs.existsSync(prsFile)) {
        const prs = JSON.parse(fs.readFileSync(prsFile, 'utf8')).pullRequests;
        prs.forEach(pr => this.state.pullRequests.set(pr.number, pr));
      }

      // Load commits
      const commitsFile = path.join(this.fixturesPath, 'commits.json');
      if (fs.existsSync(commitsFile)) {
        const commits = JSON.parse(fs.readFileSync(commitsFile, 'utf8')).commits;
        commits.forEach(commit => this.state.commits.set(commit.sha, commit));
      }

      console.log('[GitHubMock] Fixtures loaded successfully');
      console.log(`  Repositories: ${this.state.repositories.size}`);
      console.log(`  Pull Requests: ${this.state.pullRequests.size}`);
      console.log(`  Commits: ${this.state.commits.size}`);
    } catch (error) {
      console.error('[GitHubMock] Error loading fixtures:', error);
    }
  }

  async handleRequest(method, params) {
    this.requestCount++;

    // Simulate rate limiting
    if (this.requestCount > this.rateLimitThreshold) {
      throw {
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Rate limit exceeded. Please try again later.',
        retryAfter: 3600
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
      // Repository operations
      case 'github_get_repository':
        return this.getRepository(params);
      case 'github_list_repositories':
        return this.listRepositories(params);

      // Pull request operations
      case 'github_create_pull_request':
        return this.createPullRequest(params);
      case 'github_get_pull_request':
        return this.getPullRequest(params);
      case 'github_list_pull_requests':
        return this.listPullRequests(params);
      case 'github_update_pull_request':
        return this.updatePullRequest(params);
      case 'github_merge_pull_request':
        return this.mergePullRequest(params);

      // Commit operations
      case 'github_get_commit':
        return this.getCommit(params);
      case 'github_list_commits':
        return this.listCommits(params);

      // Branch operations
      case 'github_get_branch':
        return this.getBranch(params);
      case 'github_list_branches':
        return this.listBranches(params);
      case 'github_create_branch':
        return this.createBranch(params);

      // Comment operations
      case 'github_create_pr_comment':
        return this.createPRComment(params);
      case 'github_list_pr_comments':
        return this.listPRComments(params);

      // Review operations
      case 'github_create_review':
        return this.createReview(params);
      case 'github_list_reviews':
        return this.listReviews(params);

      default:
        throw {
          code: 'METHOD_NOT_FOUND',
          message: `Unknown method: ${method}`
        };
    }
  }

  // Repository operations
  getRepository(params) {
    const key = `${params.owner}/${params.repo}`;
    const repo = this.state.repositories.get(key);
    if (!repo) {
      throw {
        code: 'NOT_FOUND',
        message: `Repository not found: ${key}`,
        suggestions: [
          'Verify the owner and repository name',
          `Available repos: ${Array.from(this.state.repositories.keys()).join(', ')}`
        ]
      };
    }
    return repo;
  }

  listRepositories(params) {
    let repos = Array.from(this.state.repositories.values());

    if (params.org) {
      repos = repos.filter(r => r.owner.login === params.org);
    }

    return { repositories: repos };
  }

  // Pull request operations
  createPullRequest(params) {
    const repoKey = `${params.owner}/${params.repo}`;
    const repo = this.state.repositories.get(repoKey);
    if (!repo) {
      throw {
        code: 'NOT_FOUND',
        message: `Repository not found: ${repoKey}`
      };
    }

    const prNumber = this.state.pullRequests.size + 1;
    const pr = {
      id: Date.now(),
      number: prNumber,
      title: params.title,
      body: params.body || '',
      state: 'open',
      head: {
        ref: params.head,
        sha: `sha-${Date.now()}`
      },
      base: {
        ref: params.base,
        sha: 'base-sha'
      },
      user: {
        login: 'test-user'
      },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      html_url: `https://github.com/${repoKey}/pull/${prNumber}`,
      mergeable: true,
      mergeable_state: 'clean'
    };

    this.state.pullRequests.set(pr.number, pr);
    return pr;
  }

  getPullRequest(params) {
    const pr = this.state.pullRequests.get(params.prNumber);
    if (!pr) {
      throw {
        code: 'NOT_FOUND',
        message: `Pull request not found: #${params.prNumber}`,
        suggestions: [
          'Verify the PR number is correct',
          `Available PRs: ${Array.from(this.state.pullRequests.keys()).join(', ')}`
        ]
      };
    }
    return pr;
  }

  listPullRequests(params) {
    let prs = Array.from(this.state.pullRequests.values());

    if (params.state) {
      prs = prs.filter(pr => pr.state === params.state);
    }

    if (params.head) {
      prs = prs.filter(pr => pr.head.ref === params.head);
    }

    if (params.base) {
      prs = prs.filter(pr => pr.base.ref === params.base);
    }

    return { pullRequests: prs };
  }

  updatePullRequest(params) {
    const pr = this.state.pullRequests.get(params.prNumber);
    if (!pr) {
      throw {
        code: 'NOT_FOUND',
        message: `Pull request not found: #${params.prNumber}`
      };
    }

    const updatedPR = {
      ...pr,
      title: params.title || pr.title,
      body: params.body !== undefined ? params.body : pr.body,
      state: params.state || pr.state,
      updated_at: new Date().toISOString()
    };

    this.state.pullRequests.set(params.prNumber, updatedPR);
    return updatedPR;
  }

  mergePullRequest(params) {
    const pr = this.state.pullRequests.get(params.prNumber);
    if (!pr) {
      throw {
        code: 'NOT_FOUND',
        message: `Pull request not found: #${params.prNumber}`
      };
    }

    if (pr.state === 'closed') {
      throw {
        code: 'CONFLICT',
        message: 'Pull request is already closed'
      };
    }

    const mergedPR = {
      ...pr,
      state: 'closed',
      merged: true,
      merged_at: new Date().toISOString(),
      merge_commit_sha: `merge-${Date.now()}`
    };

    this.state.pullRequests.set(params.prNumber, mergedPR);
    return {
      sha: mergedPR.merge_commit_sha,
      merged: true,
      message: 'Pull request successfully merged'
    };
  }

  // Commit operations
  getCommit(params) {
    const commit = this.state.commits.get(params.sha);
    if (!commit) {
      throw {
        code: 'NOT_FOUND',
        message: `Commit not found: ${params.sha}`
      };
    }
    return commit;
  }

  listCommits(params) {
    let commits = Array.from(this.state.commits.values());

    if (params.sha) {
      // Filter commits from a specific SHA
      commits = commits.filter(c => c.sha.startsWith(params.sha));
    }

    if (params.path) {
      // Filter commits that modified a specific path
      commits = commits.filter(c =>
        c.files?.some(f => f.filename.includes(params.path))
      );
    }

    return { commits };
  }

  // Branch operations
  getBranch(params) {
    const branch = this.state.branches.get(params.branch);
    if (!branch) {
      throw {
        code: 'NOT_FOUND',
        message: `Branch not found: ${params.branch}`
      };
    }
    return branch;
  }

  listBranches(params) {
    const branches = Array.from(this.state.branches.values());
    return { branches };
  }

  createBranch(params) {
    if (this.state.branches.has(params.branch)) {
      throw {
        code: 'CONFLICT',
        message: `Branch already exists: ${params.branch}`
      };
    }

    const branch = {
      name: params.branch,
      commit: {
        sha: params.sha || 'base-sha',
        url: `https://api.github.com/repos/${params.owner}/${params.repo}/commits/${params.sha}`
      },
      protected: false
    };

    this.state.branches.set(params.branch, branch);
    return branch;
  }

  // Comment operations
  createPRComment(params) {
    const pr = this.state.pullRequests.get(params.prNumber);
    if (!pr) {
      throw {
        code: 'NOT_FOUND',
        message: `Pull request not found: #${params.prNumber}`
      };
    }

    const commentId = Date.now();
    const comment = {
      id: commentId,
      body: params.body,
      user: {
        login: 'test-user'
      },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      html_url: `https://github.com/test/repo/pull/${params.prNumber}#issuecomment-${commentId}`
    };

    const prComments = this.state.comments.get(params.prNumber) || [];
    prComments.push(comment);
    this.state.comments.set(params.prNumber, prComments);

    return comment;
  }

  listPRComments(params) {
    const comments = this.state.comments.get(params.prNumber) || [];
    return { comments };
  }

  // Review operations
  createReview(params) {
    const pr = this.state.pullRequests.get(params.prNumber);
    if (!pr) {
      throw {
        code: 'NOT_FOUND',
        message: `Pull request not found: #${params.prNumber}`
      };
    }

    const reviewId = Date.now();
    const review = {
      id: reviewId,
      body: params.body || '',
      state: params.event || 'COMMENTED', // APPROVE, REQUEST_CHANGES, COMMENT
      user: {
        login: 'test-user'
      },
      submitted_at: new Date().toISOString(),
      html_url: `https://github.com/test/repo/pull/${params.prNumber}#pullrequestreview-${reviewId}`
    };

    const prReviews = this.state.reviews.get(params.prNumber) || [];
    prReviews.push(review);
    this.state.reviews.set(params.prNumber, prReviews);

    return review;
  }

  listReviews(params) {
    const reviews = this.state.reviews.get(params.prNumber) || [];
    return { reviews };
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
        retryAfter: 3600
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
      repositories: new Map(),
      pullRequests: new Map(),
      commits: new Map(),
      branches: new Map(),
      issues: new Map(),
      comments: new Map(),
      reviews: new Map()
    };
    this.loadFixtures();
  }

  getStats() {
    return {
      requestCount: this.requestCount,
      repositories: this.state.repositories.size,
      pullRequests: this.state.pullRequests.size,
      commits: this.state.commits.size,
      branches: this.state.branches.size,
      comments: this.state.comments.size,
      reviews: this.state.reviews.size
    };
  }
}

// HTTP server wrapper
function createServer(mockServer, port = 3003) {
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
    console.log(`[GitHubMock] Server listening on http://localhost:${port}`);
  });

  return server;
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const port = args.includes('--port') ? parseInt(args[args.indexOf('--port') + 1]) : 3003;
  const fixturesPath = args.includes('--fixtures')
    ? args[args.indexOf('--fixtures') + 1]
    : path.join(__dirname, '../fixtures/github');

  const mockServer = new GitHubMockServer(fixturesPath);
  createServer(mockServer, port);
}

module.exports = { GitHubMockServer, createServer };
