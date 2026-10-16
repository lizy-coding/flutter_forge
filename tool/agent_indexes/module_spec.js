const fs = require('fs');
const path = require('path');
const { categoryComments } = require('./catalog');
const { capabilities, resolvePolicy, validateRestriction } = require('./availability');
const { moduleContract } = require('./contracts');

// Loading this helper reads no module sources or generated documents. Candidates
// remain pending, and the registration fragment never updates the real registry.
function candidateFromOptions(options, root = path.resolve(__dirname, '../..')) {
  const allowed = ['category', 'name', 'title', 'subtitle', 'difficulty', 'minutes', 'concepts', 'depends',
    'optional-capabilities', 'restriction-reason', 'restriction-sources', 'output', 'apply', 'force'];
  for (const [key, value] of Object.entries(options)) {
    if (!allowed.includes(key) || typeof value !== 'string') throw new Error(`Unknown or invalid option: --${key}`);
  }
  function required(key) {
    const value = options[key]?.trim();
    if (!value) throw new Error(`--${key} is required`);
    return value;
  }
  function list(key, fallback = '') {
    const values = (options[key] ?? fallback).split(',').map((item) => item.trim()).filter(Boolean);
    if (new Set(values).size !== values.length) throw new Error(`Duplicate values: --${key}`);
    return values;
  }
  const category = required('category');
  const id = required('name');
  if (!Object.hasOwn(categoryComments, category)) throw new Error(`Invalid category: ${category}`);
  if (!/^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$/.test(id)) throw new Error(`Invalid module name: ${id}`);
  const difficulty = options.difficulty ?? 'beginner';
  if (!['beginner', 'intermediate', 'advanced'].includes(difficulty)) throw new Error(`Invalid difficulty: ${difficulty}`);
  const estimatedMinutes = Number(options.minutes ?? '15');
  if (!Number.isInteger(estimatedMinutes) || estimatedMinutes <= 0) throw new Error('Minutes must be a positive integer');
  const concepts = list('concepts', 'Flutter,实践');
  if (!concepts.length) throw new Error('Concepts must not be empty');
  const additional = list('depends');
  if (additional.some((item) => !/^[a-z][a-z0-9_]*$/.test(item))) throw new Error('Invalid module dependency');
  const optionalCapabilities = list('optional-capabilities');
  if (optionalCapabilities.some((id) => !Object.hasOwn(capabilities, id))) throw new Error('Unknown optional capability');
  const declaration = {
    category, id, route: `/${id.replaceAll('_', '-')}`, status: 'pending',
    depends: [...new Set(['shared_learning', 'module_registry', ...additional])],
    title: required('title'), subtitle: required('subtitle'), difficulty, concepts, estimatedMinutes,
    entry: `${id.split('_').map((part) => part[0].toUpperCase() + part.slice(1)).join('')}Entry`,
    validation: ['flutter analyze', `flutter test test/modules/${category}/${id}`],
    ...(optionalCapabilities.length ? { optionalCapabilities } : {}),
  };
  if (Object.hasOwn(options, 'restriction-reason') || Object.hasOwn(options, 'restriction-sources')) {
    declaration.entryRestriction = { reason: required('restriction-reason'), sources: list('restriction-sources') };
    validateRestriction(root, declaration);
  }
  // The generated files import only Flutter and shared learning. Additional
  // dependencies are deliberate candidate intent, not a claim of implementation.
  const resolved = resolvePolicy(declaration, { imports: ['package:flutter/material.dart',
    'package:flutter_forge_app/shared/learning/learning_scaffold.dart'], names: ['module_entry.dart', 'module_root.dart'] });
  const contract = moduleContract(resolved, ['module_entry.dart', 'module_root.dart']);
  return {
    spec: { schema: 'flutter_forge.module_candidate.v1', declaration,
      platform_support: contract.platform_support, routeRegistration: 'explicit_review_required' },
    contract,
    registration: `// Review this pending candidate before adding it to the modules declaration.\n${JSON.stringify(declaration, null, 2)},\n`,
  };
}

if (require.main === module) {
  try {
    process.stdout.write(`${JSON.stringify(candidateFromOptions(JSON.parse(fs.readFileSync(0, 'utf8'))))}\n`);
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 64;
  }
}

module.exports = { candidateFromOptions };
