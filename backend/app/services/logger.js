/**
 * Structured Logging Service
 *
 * Provides structured JSON logging with correlation tracking, log level filtering,
 * and automatic sanitization of sensitive data.
 *
 * In development the terminal gets a short, colored one-line summary per
 * entry instead of a raw JSON blob — a green check for a clean request or
 * info log, a red cross for an error, an amber warning triangle otherwise.
 * The full structured JSON (needed for log aggregation) is still what ships
 * when NODE_ENV=production, or whenever LOG_FORMAT=json is set explicitly.
 *
 * @module services/logger
 */

import { AsyncLocalStorage } from 'async_hooks';
import processRole from '../core/processRole.js';

const { getProcessRole } = processRole;

// AsyncLocalStorage for request context (correlation ID)
const asyncLocalStorage = new AsyncLocalStorage();

// Log levels
const LOG_LEVELS = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3
};

// A real terminal wants a short colored line, not a JSON document — but a
// log aggregator in production wants the opposite, so the two modes are
// picked here once rather than scattered through every call site.
const PRETTY_LOGS =
  (process.env.LOG_FORMAT || '').toLowerCase() !== 'json' &&
  process.env.NODE_ENV !== 'production';

const ANSI = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  gray: '\x1b[90m',
};

// process.stdout.isTTY is false when output is piped/redirected — colors
// would just show up as literal escape codes there, so skip them.
const COLOR_ENABLED = Boolean(process.stdout.isTTY);

function paint(color, text) {
  if (!COLOR_ENABLED) return text;
  return `${ANSI[color] || ''}${text}${ANSI.reset}`;
}

const LEVEL_BADGE = {
  error: () => paint('red', '✖ ERROR'),
  warn: () => paint('yellow', '⚠ WARN '),
  info: () => paint('cyan', 'ℹ INFO '),
  debug: () => paint('gray', '• DEBUG'),
};

/** A handful of fields worth a glance inline; everything else is noise. */
const PRETTY_CONTEXT_KEYS = [
  'statusCode',
  'duration',
  'method',
  'path',
  'route',
  'userId',
  'code',
  'port',
];

function formatPrettyContext(context = {}) {
  const parts = [];
  for (const key of PRETTY_CONTEXT_KEYS) {
    if (context[key] === undefined || context[key] === null) continue;
    const value = key === 'duration' ? `${context[key]}ms` : context[key];
    parts.push(`${key}=${value}`);
  }
  return parts.length ? paint('dim', parts.join(' ')) : '';
}

/**
 * One compact, human-scannable line per log entry.
 *
 * HTTP request completions are the overwhelming majority of lines a running
 * server prints, so they get their own tighter layout — method, path and
 * status lined up — rather than sharing the generic "badge + message" shape.
 */
function formatPrettyLine(level, message, context = {}) {
  if (message === 'HTTP request completed' && context.method) {
    const icon =
      level === 'error' ? paint('red', '✖') : level === 'warn' ? paint('yellow', '●') : paint('green', '✓');
    const status = String(context.statusCode ?? '---').padEnd(3);
    const statusColor = level === 'error' ? 'red' : level === 'warn' ? 'yellow' : 'green';
    const method = String(context.method).padEnd(6);
    const duration = context.duration != null ? paint('dim', `${context.duration}ms`) : '';
    return `${icon} ${paint(statusColor, status)} ${method} ${context.path || ''} ${duration}`.trimEnd();
  }

  const badge = (LEVEL_BADGE[level] || LEVEL_BADGE.info)();
  const contextStr = formatPrettyContext(context);

  let line = `${badge} ${message}`;
  if (contextStr) line += `  ${contextStr}`;

  // An attached Error is the one thing worth a second line — its stack is
  // how a failure actually gets diagnosed, JSON blob or not.
  if (context.error?.stack) {
    line += `\n${paint('dim', context.error.stack)}`;
  } else if (context.error?.message) {
    line += `  ${paint('red', context.error.message)}`;
  }

  return line;
}

// Sensitive field patterns to redact
const SENSITIVE_PATTERNS = [
  /password/i,
  /token/i,
  /apikey/i,
  /api_key/i,
  /secret/i,
  /authorization/i,
  /bearer/i,
  /otp/i,
  /pin/i,
  /signature/i,
  /cookie/i,
  /privatekey/i,
];

/**
 * Get current log level from environment
 * @returns {number}
 */
function getCurrentLogLevel() {
  const level = (process.env.LOG_LEVEL || 'info').toLowerCase();
  return LOG_LEVELS[level] !== undefined ? LOG_LEVELS[level] : LOG_LEVELS.info;
}

/**
 * Get correlation ID from async context
 * @returns {string|undefined}
 */
function getCorrelationId() {
  const store = asyncLocalStorage.getStore();
  return store?.correlationId;
}

/**
 * Set correlation ID in async context
 * @param {string} correlationId
 * @param {Function} callback
 */
function runWithCorrelationId(correlationId, callback) {
  asyncLocalStorage.run({ correlationId }, callback);
}

/**
 * Sanitize sensitive data from logs
 * @param {*} data - Data to sanitize
 * @returns {*} Sanitized data
 */
function sanitize(data) {
  if (!data || typeof data !== 'object') {
    return data;
  }
  
  if (Array.isArray(data)) {
    return data.map(item => sanitize(item));
  }
  
  const sanitized = {};
  
  for (const [key, value] of Object.entries(data)) {
    // Check if key matches sensitive patterns
    const isSensitive = SENSITIVE_PATTERNS.some(pattern => pattern.test(key));
    
    if (isSensitive) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'string') {
      // Mask credit card numbers (keep last 4 digits)
      const ccPattern = /\b\d{13,19}\b/g;
      let maskedValue = value.replace(ccPattern, (match) => {
        return '*'.repeat(match.length - 4) + match.slice(-4);
      });
      
      // Mask phone numbers (keep first 3 and last 2 digits)
      const phonePattern = /\b\d{10,15}\b/g;
      maskedValue = maskedValue.replace(phonePattern, (match) => {
        if (match.length >= 5) {
          return match.slice(0, 3) + '*'.repeat(match.length - 5) + match.slice(-2);
        }
        return match;
      });
      
      sanitized[key] = maskedValue;
    } else if (typeof value === 'object' && value !== null) {
      sanitized[key] = sanitize(value);
    } else {
      sanitized[key] = value;
    }
  }
  
  return sanitized;
}

/**
 * Format log entry as structured JSON
 * @param {string} level - Log level
 * @param {string} message - Log message
 * @param {Object} context - Additional context
 * @returns {Object}
 */
function formatLogEntry(level, message, context = {}) {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    correlationId: getCorrelationId(),
    role: getProcessRole(),
    environment: process.env.NODE_ENV || 'development'
  };
  
  // Add context if provided
  if (context && Object.keys(context).length > 0) {
    entry.context = sanitize(context);
  }
  
  return entry;
}

/**
 * Log with structured format
 * @param {string} level - Log level (error, warn, info, debug)
 * @param {string} message - Log message
 * @param {Object} context - Additional context
 */
function log(level, message, context = {}) {
  const currentLevel = getCurrentLogLevel();
  const messageLevel = LOG_LEVELS[level];
  
  // Filter out logs below current level
  if (messageLevel === undefined || messageLevel > currentLevel) {
    return;
  }
  
  const entry = formatLogEntry(level, message, context);
  const output = PRETTY_LOGS
    ? formatPrettyLine(level, message, entry.context)
    : JSON.stringify(entry);

  // Use appropriate console method
  if (level === 'error') {
    console.error(output);
  } else if (level === 'warn') {
    console.warn(output);
  } else {
    console.log(output);
  }
}

/**
 * Log error message
 * @param {string} message - Error message
 * @param {Object} context - Additional context (can include error object)
 */
function error(message, context = {}) {
  // If context contains an Error object, extract details
  if (context.error instanceof Error) {
    context.error = {
      message: context.error.message,
      code: context.error.code,
      stack: context.error.stack
    };
  }
  
  log('error', message, context);
}

/**
 * Log warning message
 * @param {string} message - Warning message
 * @param {Object} context - Additional context
 */
function warn(message, context = {}) {
  log('warn', message, context);
}

/**
 * Log info message
 * @param {string} message - Info message
 * @param {Object} context - Additional context
 */
function info(message, context = {}) {
  log('info', message, context);
}

/**
 * Log debug message
 * @param {string} message - Debug message
 * @param {Object} context - Additional context
 */
function debug(message, context = {}) {
  log('debug', message, context);
}

/**
 * Create child logger with persistent context
 * @param {Object} persistentContext - Context to include in all logs
 * @returns {Object} Child logger with same methods
 */
function child(persistentContext = {}) {
  return {
    log: (level, message, context = {}) => 
      log(level, message, { ...persistentContext, ...context }),
    error: (message, context = {}) => 
      error(message, { ...persistentContext, ...context }),
    warn: (message, context = {}) => 
      warn(message, { ...persistentContext, ...context }),
    info: (message, context = {}) => 
      info(message, { ...persistentContext, ...context }),
    debug: (message, context = {}) => 
      debug(message, { ...persistentContext, ...context }),
    child: (additionalContext = {}) => 
      child({ ...persistentContext, ...additionalContext })
  };
}

const logger = {
  log,
  error,
  warn,
  info,
  debug,
  child,
  sanitize,
  runWithCorrelationId,
  getCorrelationId,
  LOG_LEVELS
};

export {
  log,
  error,
  warn,
  info,
  debug,
  child,
  sanitize,
  runWithCorrelationId,
  getCorrelationId,
  LOG_LEVELS
};

export default logger;
