# Planning Strategy Guide - Detailed Examples

Comprehensive examples showing how to use the planning-strategy-guide skill for various scenarios.

## Table of Contents

1. [E-commerce Feature Planning](#example-1-e-commerce-feature-planning)
2. [Bug Fix Planning](#example-2-bug-fix-planning)
3. [API Migration Planning](#example-3-api-migration-planning)
4. [Mobile App Feature](#example-4-mobile-app-feature)
5. [Performance Optimization](#example-5-performance-optimization)

---

## Example 1: E-commerce Feature Planning

### Scenario

User wants to add product recommendations to their e-commerce site.

### User Request

> "I need to add product recommendations on the product detail page. Show similar products based on category and price range."

### Planning Strategy Guide Activation

```
[planning-strategy-guide activates]

I'll help you plan the product recommendations feature. Let me run through the planning phases:
```

### Phase 1: Complexity Assessment

**Analysis**:
- Files to modify: 6-8 (API endpoint, recommendation logic, UI component, tests)
- External dependencies: None (unless using ML service)
- Research needed: Recommendation algorithms (1-2 hours)
- Technical risk: Medium (algorithm selection)

**Complexity**: **Medium** (3-8 files, 2-3 days)

### Phase 2: Scope Definition

**In Scope**:
- Display 4-6 similar products on product detail page
- Similarity based on category + price range (+/- 20%)
- Products from same seller excluded
- Click tracking for recommendations

**Out of Scope (defer to v2)**:
- ML-based personalized recommendations
- Cross-category recommendations
- User behavior tracking
- A/B testing framework

**Acceptance Criteria**:
1. ✅ Recommendations appear below product description
2. ✅ Show max 6 products, sorted by relevance
3. ✅ Page loads in < 2s (including recommendations)
4. ✅ Click tracking working (analytics event fired)
5. ✅ No recommendations shown if < 2 similar products available

### Phase 3: Dependency Analysis

**Hard Dependencies**:
1. Product data API must be available
2. Category taxonomy must be stable
3. Database indexes on category + price fields

**Soft Dependencies**:
- Analytics service for click tracking (can defer)

**Parallel Work**:
- Frontend component (Team A)
- Backend API endpoint (Team B)
- Database optimization (Team C)

**Critical Path**:
Database indexes → API endpoint → Frontend component

### Phase 4: Risk Identification

| Risk | Likelihood | Impact | Mitigation | Contingency |
|------|------------|--------|------------|-------------|
| Slow query performance | High | High | Add database indexes, cache results | Use simpler algorithm |
| Too many/few results | Medium | Low | Add min/max thresholds | Manual product curation |
| Click tracking breaks | Low | Low | Defensive error handling | Degrade gracefully |

### Phase 5: Task Breakdown

```
Epic: Product Recommendations
├── Backend
│   ├── Add database indexes (category, price, seller_id)
│   ├── Create recommendation API endpoint
│   │   ├── Query logic (category + price range)
│   │   ├── Exclude same seller
│   │   ├── Limit to 6 results
│   │   └── Add caching (Redis, 15min TTL)
│   └── Write API tests
├── Frontend
│   ├── Create RecommendedProducts component
│   │   ├── Fetch from API on mount
│   │   ├── Display product cards
│   │   ├── Handle loading/error states
│   │   └── Fire click tracking event
│   ├── Add to ProductDetailPage
│   └── Write component tests
└── Analytics
    ├── Add click tracking event
    └── Create analytics dashboard tile
```

### Phase 6: Effort Estimation

| Task | T-Shirt | Story Points | Estimate |
|------|---------|--------------|----------|
| Database indexes | S | 2 | 4h |
| API endpoint + tests | M | 5 | 1d |
| Frontend component + tests | M | 5 | 1d |
| Analytics tracking | S | 2 | 4h |
| **Total** | **-** | **14** | **2.5d** |

**With buffer (20%)**: 3 days

### Output

```
✅ Planning Complete!

📊 Summary:
  • Complexity: Medium
  • Tasks: 8 subtasks
  • Dependencies: 1 hard dependency (database indexes)
  • Risks: 1 high-priority (performance)
  • Estimate: 3 days (with buffer)

💡 Next Steps:
  1. Create Linear issue: /ccpm:plan "Product Recommendations"
  2. Start with database indexes (critical path)
  3. Frontend and backend can proceed in parallel after indexes

📋 Implementation Order:
  Day 1: Database indexes + API endpoint
  Day 2: Frontend component + tests
  Day 3: Analytics + QA testing
```

---

## Example 2: Bug Fix Planning

### Scenario

Application crashes when user uploads large images (>5MB).

### User Request

> "Fix the crash when uploading large images. It happens on the profile photo upload."

### Planning Strategy Guide Activation (Lightweight)

```
[planning-strategy-guide activates - lightweight mode for bug fix]

Let me assess this bug fix:
```

### Phase 1: Complexity Assessment

**Analysis**:
- Files to modify: 2-3 (upload component, validation logic, maybe backend)
- Root cause: Likely missing file size validation
- Research needed: Minimal (< 30min)
- Technical risk: Low

**Complexity**: **Simple** (1-2 files, 2-4 hours)

### Phase 4: Risk Identification (Quick Check)

| Risk | Mitigation |
|------|------------|
| Client-side validation bypass | Add server-side validation too |
| UX confusion | Show clear error message with max size |

### Phase 5: Task Breakdown (Minimal)

```
Bug Fix: Large Image Upload Crash
├── Add client-side file size validation (before upload)
├── Add server-side file size validation (safety)
├── Display user-friendly error message
├── Add image compression option (optional)
└── Write regression test
```

### Phase 6: Effort Estimation

**Estimate**: 2-4 hours

**Breakdown**:
- Client validation: 30min
- Server validation: 1h
- Error message UX: 30min
- Testing: 1h

### Output

```
✅ Bug Fix Plan:

📊 Summary:
  • Complexity: Simple
  • Tasks: 4 subtasks (5 if compression added)
  • Estimate: 2-4 hours

🔧 Quick Fix:
  1. Add max file size check (5MB limit)
  2. Show error: "Please upload images smaller than 5MB"
  3. Add server-side validation (safety)
  4. Write test to prevent regression

💡 Start now:
  /ccpm:plan "Fix large image upload crash"
```

---

## Example 3: API Migration Planning

### Scenario

Migrating from REST API v1 to GraphQL.

### User Request

> "We need to migrate our user management API from REST to GraphQL. We have about 20 REST endpoints currently."

### Planning Strategy Guide Activation

```
[planning-strategy-guide activates]

This is a significant migration. Let me do comprehensive planning:
```

### Phase 1: Complexity Assessment

**Analysis**:
- Files to modify: 30+ (GraphQL schema, resolvers, client code)
- External dependencies: All clients using current API
- Research needed: GraphQL best practices (4-6 hours)
- Technical risk: High (breaking changes, client coordination)

**Complexity**: **Complex** (30+ files, 2-3 weeks)

### Phase 2: Scope Definition

**In Scope**:
- GraphQL schema for user management
- 20 REST endpoints → GraphQL queries/mutations
- Parallel running (v1 REST + v2 GraphQL)
- Client migration guide
- Performance testing

**Out of Scope**:
- Other API domains (keep REST for now)
- Real-time subscriptions (defer to v3)
- Deprecating v1 REST (run both for 6 months)

**Success Metrics**:
- 100% feature parity with REST v1
- Response time < REST v1
- 0 client breaking changes during migration

### Phase 3: Dependency Analysis

**Hard Dependencies**:
1. GraphQL server setup (must be first)
2. Schema design (must be before resolvers)
3. Client SDK generation (depends on schema)
4. Client migration (depends on SDK)

**Execution Order**:
```
Week 1: GraphQL infrastructure + Schema design
Week 2: Resolvers + Server testing
Week 3: Client SDK + Migration guide
Week 4: Client migrations + Parallel testing
```

**Parallel Work**:
- Server team: GraphQL implementation
- Client team: Prepare for migration (Week 3+)
- QA team: Performance testing (Week 2+)

### Phase 4: Risk Identification

| Risk | Likelihood | Impact | Mitigation | Contingency |
|------|------------|--------|------------|-------------|
| Breaking client changes | High | Critical | Run both APIs in parallel, versioning | Rollback to v1 only |
| Performance degradation | Medium | High | Load testing, query optimization, caching | Add CDN caching layer |
| Schema design issues | Medium | High | Community review, iterate early | Schema evolution strategy |
| Client adoption slow | Medium | Medium | Clear migration guide, dedicated support | Extend parallel run to 12mo |
| N+1 query problems | High | High | DataLoader, query batching | Query complexity limits |

### Phase 5: Task Breakdown

```
Epic: GraphQL Migration
├── Phase 1: Infrastructure (Week 1)
│   ├── Set up GraphQL server (Apollo Server)
│   ├── Configure database connectors
│   ├── Add authentication middleware
│   ├── Set up monitoring (query logging, performance)
│   └── Deploy to staging environment
├── Phase 2: Schema & Resolvers (Week 2)
│   ├── Design GraphQL schema
│   │   ├── User types
│   │   ├── Query types
│   │   ├── Mutation types
│   │   └── Input types
│   ├── Implement resolvers
│   │   ├── User queries (10 endpoints)
│   │   ├── User mutations (10 endpoints)
│   │   └── Add DataLoader (prevent N+1)
│   ├── Add query complexity limits
│   ├── Write resolver tests
│   └── Performance testing
├── Phase 3: Client Integration (Week 3)
│   ├── Generate TypeScript client SDK
│   ├── Write migration guide
│   ├── Create example client code
│   ├── Set up client caching (Apollo Client)
│   └── Document breaking changes (if any)
├── Phase 4: Migration & Testing (Week 4)
│   ├── Migrate web app (high priority)
│   ├── Migrate mobile app
│   ├── Migrate admin dashboard
│   ├── Parallel testing (REST vs GraphQL)
│   ├── Performance comparison
│   └── Monitor error rates
└── Phase 5: Rollout & Support (Week 5+)
    ├── Production deployment
    ├── Monitor both APIs
    ├── Support client migrations
    ├── Create deprecation timeline for v1
    └── Performance optimization based on real usage
```

### Phase 6: Effort Estimation

| Phase | Story Points | Estimate |
|-------|--------------|----------|
| Infrastructure | 8 | 1 week |
| Schema & Resolvers | 21 | 1.5 weeks |
| Client Integration | 13 | 1 week |
| Migration & Testing | 13 | 1 week |
| Rollout & Support | 5 | Ongoing |
| **Total** | **60** | **4.5 weeks** |

**With buffer (30% for complex projects)**: 6 weeks

### Output

```
✅ Comprehensive Migration Plan Created!

📊 Summary:
  • Complexity: Complex (High risk, multi-team)
  • Tasks: 30+ subtasks across 5 phases
  • Dependencies: Sequential phases, some parallel work
  • Risks: 5 high-priority risks identified
  • Estimate: 6 weeks (with 30% buffer)

🚨 High-Priority Risks:
  1. Breaking client changes → Run APIs in parallel
  2. N+1 query problems → Use DataLoader
  3. Performance degradation → Load test early

💡 Recommended Approach:
  1. Create spec first: /ccpm:plan epic "GraphQL Migration"
  2. Document in sections: architecture, api-design, testing
  3. Review with team before implementation
  4. Then: /ccpm:plan (creates phases as features)

📋 Critical Path:
  Infrastructure → Schema → Resolvers → Client SDK → Migration
  (Each phase blocks the next)

⚠️  Note: This is a 6-week project. Consider:
  - Breaking into smaller features
  - Migrating one domain at a time
  - Running parallel APIs for 6+ months
```

---

## Example 4: Mobile App Feature

### Scenario

Add offline mode to mobile app for viewing saved articles.

### User Request

> "Users want to read articles offline. They should be able to save articles and view them without internet."

### Planning Strategy Guide Activation

```
[planning-strategy-guide activates - mobile context detected]

Let me plan the offline mode feature for your mobile app:
```

### Phase 1: Complexity Assessment

**Analysis**:
- Files to modify: 8-10 (offline storage, sync logic, UI indicators)
- Platform: React Native (iOS + Android)
- Research needed: Offline storage best practices (2-3 hours)
- Technical risk: Medium (sync conflicts, storage limits)

**Complexity**: **Medium** (8-10 files, 4-5 days)

### Phase 2: Scope Definition

**In Scope**:
- Save articles for offline reading (manual save)
- Offline indicator in UI
- Local storage (SQLite or AsyncStorage)
- Sync saved articles when online
- Max 50 saved articles per user

**Out of Scope**:
- Auto-sync all viewed articles (defer to v2)
- Offline editing/annotations
- Cross-device sync
- Unlimited storage

**Acceptance Criteria**:
1. ✅ User can tap "Save for offline" on any article
2. ✅ Saved articles viewable without network
3. ✅ Offline indicator shows when network unavailable
4. ✅ Articles sync when device comes online
5. ✅ User notified when approaching 50-article limit

### Phase 3: Dependency Analysis

**Hard Dependencies**:
1. Choose offline storage solution (SQLite vs Async Storage)
2. Implement storage layer before sync logic
3. UI updates depend on storage APIs

**Platform Considerations**:
- iOS: No additional permissions needed
- Android: Storage permissions (if using external storage)

**Execution Order**:
```
Day 1-2: Storage layer + data models
Day 3: Sync logic
Day 4: UI updates (save button, offline indicator)
Day 5: Testing + edge cases
```

### Phase 4: Risk Identification

| Risk | Likelihood | Impact | Mitigation | Contingency |
|------|------------|--------|------------|-------------|
| Storage quota exceeded | Medium | Medium | 50-article limit, show warning at 45 | Allow user to delete old articles |
| Sync conflicts | Low | Medium | Last-write-wins strategy | Manual conflict resolution UI |
| Images not loading offline | High | High | Download images with articles | Show text-only mode |
| Battery drain from sync | Low | Low | Sync only on WiFi by default | User setting to control |

### Phase 5: Task Breakdown

```
Feature: Offline Article Reading
├── Storage Layer
│   ├── Set up SQLite database
│   ├── Create article schema (id, title, content, images, saved_at)
│   ├── Implement CRUD operations
│   │   ├── Save article
│   │   ├── Get article by ID
│   │   ├── List all saved articles
│   │   └── Delete article
│   └── Add storage limit check (50 articles)
├── Sync Logic
│   ├── Detect online/offline state (NetInfo)
│   ├── Download article content + images on save
│   ├── Sync saved articles when online
│   ├── Handle sync errors (retry logic)
│   └── Background sync (when app in background)
├── UI Updates
│   ├── Add "Save for offline" button to article screen
│   ├── Show offline indicator in header
│   ├── Create "Saved Articles" tab
│   ├── Add article management (delete saved)
│   └── Show storage usage (X/50 articles)
└── Testing
    ├── Unit tests (storage layer)
    ├── Integration tests (sync logic)
    ├── Manual testing (airplane mode)
    └── Test on both iOS and Android
```

### Phase 6: Effort Estimation

| Component | iOS | Android | Estimate |
|-----------|-----|---------|----------|
| Storage layer | 1d | (shared) | 1d |
| Sync logic | 1d | (shared) | 1d |
| UI updates | 1d | 1d | 2d |
| Testing | 0.5d | 0.5d | 1d |
| **Total** | - | - | **5d** |

### Output

```
✅ Mobile Offline Mode Planned!

📊 Summary:
  • Complexity: Medium
  • Tasks: 14 subtasks
  • Platforms: iOS + Android (React Native)
  • Dependencies: Storage → Sync → UI
  • Risks: 1 high-priority (images offline)
  • Estimate: 5 days

📱 Platform Notes:
  • Use SQLite for robust offline storage
  • Test on both iOS and Android devices
  • Consider background sync limitations per platform

🎯 MVP Scope:
  • Manual save (not auto-sync)
  • 50 article limit
  • WiFi-only sync by default

💡 Next Steps:
  1. Research offline storage: Compare SQLite vs AsyncStorage
  2. Create Linear issue: /ccpm:plan "Offline Article Reading"
  3. Start with storage layer (critical path)

📋 Implementation Order:
  Day 1-2: SQLite setup + CRUD operations
  Day 3: Network detection + sync logic
  Day 4: UI (save button, offline indicator, saved articles tab)
  Day 5: Testing (airplane mode, edge cases)
```

---

## Example 5: Performance Optimization

### Scenario

Dashboard loads slowly (5-7 seconds), need to optimize to < 2 seconds.

### User Request

> "Our dashboard takes 5-7 seconds to load. We need it under 2 seconds. It shows charts, user stats, and recent activity."

### Planning Strategy Guide Activation

```
[planning-strategy-guide activates - performance optimization]

Let me plan the dashboard performance optimization:
```

### Phase 1: Complexity Assessment

**Analysis**:
- Files to modify: Unknown (need profiling first)
- Research needed: Profiling + bottleneck identification (4+ hours)
- Technical risk: Medium (optimization without breaking features)
- Performance target: 5-7s → <2s (60-70% reduction)

**Complexity**: **Medium to Complex** (Unknown scope until profiling)

**Recommendation**: Start with Phase 4 (Risk Identification) to identify bottlenecks

### Phase 4: Risk Identification (Profiling First)

**Profiling Questions**:
1. What takes the longest: API calls? Rendering? Data processing?
2. How many API calls are made on load?
3. Are API calls sequential or parallel?
4. How much data is being transferred?
5. Are there unnecessary re-renders?

**Potential Bottlenecks**:

| Potential Issue | Likelihood | If True → Mitigation |
|-----------------|------------|----------------------|
| Slow API calls | High | Cache responses, parallel requests, CDN |
| Large data transfer | High | Pagination, lazy loading, data compression |
| Sequential API calls | High | Parallelize with Promise.all |
| Unnecessary re-renders | Medium | React.memo, useMemo, useCallback |
| Heavy computations | Low | Web Workers, memoization |
| Large bundle size | Medium | Code splitting, lazy imports |

### Phase 5: Task Breakdown (Hypothesis-Driven)

```
Performance Optimization: Dashboard
├── Phase 1: Profiling & Measurement
│   ├── Set up performance monitoring (Lighthouse, WebPageTest)
│   ├── Add timing markers (mark/measure API)
│   ├── Profile with Chrome DevTools
│   ├── Analyze network waterfall
│   └── Identify top 3 bottlenecks
├── Phase 2: Quick Wins (Low effort, high impact)
│   ├── IF bottleneck = API calls:
│   │   ├── Parallelize API requests (Promise.all)
│   │   ├── Add API response caching (15min TTL)
│   │   └── Reduce payload size (only needed fields)
│   ├── IF bottleneck = Re-renders:
│   │   ├── Add React.memo to chart components
│   │   ├── Use useMemo for expensive calculations
│   │   └── Optimize useEffect dependencies
│   └── IF bottleneck = Bundle size:
│       ├── Lazy load charts (React.lazy)
│       ├── Code split by route
│       └── Remove unused dependencies
├── Phase 3: Deeper Optimizations
│   ├── Implement virtual scrolling (if large lists)
│   ├── Add service worker (offline caching)
│   ├── Optimize images (WebP, lazy loading)
│   ├── Move heavy computations to Web Worker
│   └── Add skeleton loading states
└── Phase 4: Measure & Iterate
    ├── Re-measure after each optimization
    ├── Validate < 2s target achieved
    ├── Add performance budgets (prevent regression)
    └── Set up continuous monitoring
```

### Phase 6: Effort Estimation (Phased Approach)

**Phase 1 (Profiling)**: 1 day
**Phase 2 (Quick wins)**: 2-3 days (depends on findings)
**Phase 3 (Deep optimizations)**: 3-5 days (if needed)

**Total**: 6-9 days (may finish early if quick wins sufficient)

### Output

```
✅ Performance Optimization Plan (Hypothesis-Driven)

📊 Current State:
  • Load time: 5-7 seconds
  • Target: < 2 seconds (60-70% reduction)
  • Scope: Dashboard with charts, stats, recent activity

🔍 Approach:
  1. Profile first (don't optimize blindly)
  2. Identify top 3 bottlenecks
  3. Apply quick wins (low effort, high impact)
  4. Measure after each change
  5. Iterate until target achieved

⚡ Potential Quick Wins:
  • Parallelize API calls (if sequential)
  • Add caching (if same data fetched multiple times)
  • Lazy load charts (if large bundle)
  • Reduce API payload size

📋 Execution Plan:
  Day 1: Profiling + identify bottlenecks
  Day 2-4: Apply quick wins based on findings
  Day 5-7: Deeper optimizations (if needed)
  Day 8-9: Measure, iterate, add monitoring

💡 Start with:
  1. Profile the dashboard: Chrome DevTools Performance tab
  2. Share findings, then proceed with optimizations
  3. Create issue: /ccpm:plan "Optimize dashboard load time"

⚠️  Important:
  - Don't optimize prematurely
  - Measure before and after each change
  - Set performance budgets to prevent regression
```

---

## Summary

These 5 examples demonstrate the planning-strategy-guide skill across different scenarios:

1. **E-commerce Feature**: Moderate complexity, comprehensive 6-phase planning
2. **Bug Fix**: Simple complexity, lightweight planning (quick assessment)
3. **API Migration**: High complexity, extensive planning with risks and rollout
4. **Mobile Feature**: Medium complexity, platform-specific considerations
5. **Performance Optimization**: Unknown scope, hypothesis-driven approach

**Key Takeaways**:

- **Match planning depth to complexity** (simple → quick, complex → thorough)
- **Always start with complexity assessment** (don't dive in blindly)
- **Risk identification prevents surprises** (especially for complex tasks)
- **Task breakdown creates actionable steps** (not vague goals)
- **Effort estimation sets expectations** (with buffers for unknowns)
- **Iterate and refine plans** (planning is continuous, not one-shot)

Use these examples as templates for your own planning sessions!
