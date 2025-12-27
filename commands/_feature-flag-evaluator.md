# Feature Flag Evaluator

Evaluates feature flags for Phase 6 rollout with deterministic rollout control and variant assignment.

## Purpose

This shared utility handles:
- Feature flag configuration loading
- Deterministic rollout control (consistent user assignment)
- Variant assignment for A/B testing
- Stage transitions (beta → early access → GA)
- User preference overrides

## Algorithm

```javascript
function evaluateFlag(userId, flagName, config) {
  // Step 1: Check if flag is enabled globally
  const flagDef = config.flags[flagName];
  if (!flagDef || !flagDef.enabled) {
    return { enabled: false, variant: 'disabled', reason: 'flag_disabled' };
  }

  // Step 2: Check minimum version requirement
  const currentVersion = getPluginVersion(); // e.g., "2.3.0-beta.1"
  if (!meetsMinVersion(currentVersion, flagDef.min_version)) {
    return {
      enabled: false,
      variant: 'old_version',
      reason: 'version_requirement_not_met',
      required_version: flagDef.min_version,
      current_version: currentVersion
    };
  }

  // Step 3: Check user overrides (highest priority)
  const userConfig = getUserConfig();
  if (flagDef.user_override && userConfig.feature_flags?.[flagName]?.override !== null) {
    const override = userConfig.feature_flags[flagName].override;
    return {
      enabled: override,
      variant: override ? 'user_enabled' : 'user_disabled',
      reason: 'user_override'
    };
  }

  // Step 4: Deterministic rollout assignment
  // Use hash(userId + flagName + salt) % 100 for consistent assignment
  const hash = deterministicHash(userId, flagName);
  const rolloutPercentage = flagDef.rollout_percentage || 0;

  if (hash >= rolloutPercentage) {
    return {
      enabled: false,
      variant: 'not_in_rollout',
      reason: 'rollout_percentage_not_reached',
      rollout_percentage: rolloutPercentage,
      user_hash: hash
    };
  }

  // Step 5: Assign variant based on rollout
  const variant = assignVariant(flagDef.variants, hash);
  return {
    enabled: true,
    variant: variant,
    reason: 'flag_enabled',
    rollout_percentage: rolloutPercentage
  };
}

function assignVariant(variants, hash) {
  // Assign control or treatment variant
  if (!variants) return 'default';

  let cumulativePercentage = 0;
  for (const [variantName, variantDef] of Object.entries(variants)) {
    const variantPercentage = variantDef.percentage || 50;
    if (hash < cumulativePercentage + variantPercentage) {
      return variantName;
    }
    cumulativePercentage += variantPercentage;
  }

  return 'default';
}

function deterministicHash(userId, flagName) {
  // Simple deterministic hash: consistent across calls
  const combined = `${userId}:${flagName}`;
  let hash = 0;
  for (let i = 0; i < combined.length; i++) {
    const char = combined.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash % 100);
}

function meetsMinVersion(current, required) {
  // Semantic version comparison
  const currentParts = current.split(/[.-]/);
  const requiredParts = required.split(/[.-]/);

  for (let i = 0; i < Math.max(currentParts.length, requiredParts.length); i++) {
    const curr = parseInt(currentParts[i]) || 0;
    const req = parseInt(requiredParts[i]) || 0;

    if (curr > req) return true;
    if (curr < req) return false;
  }
  return true;
}
```

## Feature Flag Caching

Feature flags are loaded and cached at startup with 60-second refresh interval:

```javascript
class FeatureFlagCache {
  constructor() {
    this.cache = new Map();
    this.lastRefresh = 0;
    this.refreshInterval = 60000; // 60 seconds
  }

  async getFlag(userId, flagName) {
    // Return cached result if fresh
    const cacheKey = `${userId}:${flagName}`;
    if (this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey);
      if (Date.now() - cached.timestamp < this.refreshInterval) {
        return cached.value;
      }
    }

    // Load and cache flag configuration
    const config = await loadFeatureFlagsConfig();
    const result = evaluateFlag(userId, flagName, config);

    this.cache.set(cacheKey, {
      value: result,
      timestamp: Date.now()
    });

    return result;
  }

  invalidate(userId, flagName) {
    const cacheKey = `${userId}:${flagName}`;
    this.cache.delete(cacheKey);
  }

  clear() {
    this.cache.clear();
  }
}
```

## User Configuration

Users can override feature flags in `~/.claude/ccpm-config.json`:

```json
{
  "feature_flags": {
    "optimized_workflow_commands": {
      "override": true,
      "enabled": true
    },
    "linear_subagent_enabled": {
      "override": false,
      "enabled": false
    }
  }
}
```

## Stage Transitions

Feature flags automatically transition through stages based on configuration:

```
Beta (Dec 9) → 10% rollout
   ↓
Early Access (Dec 21) → 30% rollout
   ↓
General Availability (Jan 6) → 100% rollout
```

Stages are managed automatically by checking current date against `rollout_schedule` in feature-flags.json.

## Integration with Commands

All commands should check feature flags before execution:

```markdown
Task(feature-flag-evaluator): `
userId: {{currentUserId}}
flag: "optimized_workflow_commands"
`

If result.enabled is true:
  - Use optimized implementation
Else:
  - Use legacy implementation
```

## Monitoring

Feature flag evaluator tracks:
- Number of users in each rollout stage
- Variant distribution
- Override usage
- Cache hit rates
- Evaluation latency

Metrics are stored in `.ccpm/metrics.json` and used for dashboards.

## Admin Commands

Admins can manage feature flags via commands:

```bash
# View current feature flag status
/ccpm:admin:flags --show

# Manually set rollout percentage
/ccpm:admin:flags --set optimized_workflow_commands --percentage 50

# Override flag for specific user
/ccpm:admin:flags --set optimized_workflow_commands --user-override true

# Trigger automatic rollback
/ccpm:admin:flags --rollback optimized_workflow_commands

# View metrics
/ccpm:admin:flags --metrics
```

## Testing

Feature flags can be tested in isolated environments:

```bash
# Test with specific rollout percentage
CCPM_FEATURE_FLAG_OVERRIDE=optimized_workflow_commands:50 claude --code

# Test with specific variant
CCPM_FEATURE_FLAG_VARIANT=optimized_workflow_commands:treatment claude --code

# Disable all new features
CCPM_FEATURE_FLAGS_DISABLED=true claude --code
```

## Rollback Procedures

### Automatic Rollback (Monitoring)

When critical error threshold reached (5%+ error rate):

1. Monitoring detects error rate spike
2. Automatically disables flag via feature-flags.json update
3. Routes traffic to control variant
4. Sends alert to on-call engineer
5. No user action required (automatic recovery)

### Manual Rollback (User-Initiated)

User can disable feature flag:

```bash
/ccpm:config feature-flags optimized_workflow_commands false
```

### Emergency Rollback (Team-Initiated)

Team can trigger full rollback:

```bash
/ccpm:admin:flags --emergency-rollback optimized_workflow_commands
```

This immediately sets rollout_percentage to 0 and notifies all affected users.

## Success Metrics

Feature flag evaluator success is measured by:

- ✅ Consistent user assignment (same user gets same variant every time)
- ✅ Accurate rollout percentages (±2% deviation allowed)
- ✅ Sub-100ms evaluation latency
- ✅ >90% cache hit rate
- ✅ Zero cache invalidation bugs
- ✅ Deterministic, reproducible results

## References

- `.ccpm/feature-flags.json` - Feature flag configuration
- `~/.claude/ccpm-config.json` - User overrides
- `.ccpm/metrics.json` - Evaluation metrics
- `docs/guides/feature-flag-configuration.md` - User guide
- `docs/architecture/feature-flag-system.md` - Design document
