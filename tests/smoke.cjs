const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

test('Страница имеет четыре режима, а модуль JavaScript синтаксически корректен', () => {
  const page = fs.readFileSync(path.join(__dirname, '../docs/index.html'), 'utf8');
  assert.equal([...page.matchAll(/<option value="(?:supabase|firebase)-(?:manual|live)"/g)].length, 4);
  new vm.SourceTextModule(page.match(/<script type="module">([\s\S]*?)<\/script>/)[1]);
});
