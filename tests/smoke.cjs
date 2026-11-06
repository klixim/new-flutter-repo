const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

test('Страница имеет режимы Firebase, исключена локальная демонстрация, а модуль JS синтаксически корректен', () => {
  const page = fs.readFileSync(path.join(__dirname, '../docs/index.html'), 'utf8');
  assert.equal([...page.matchAll(/<option value="firebase-(?:manual|live)"/g)].length, 2);
  assert.equal(page.includes('id="demo"'), false, 'Кнопка локальной демонстрации должна отсутствовать');
  assert.equal(page.includes('Локальная демонстрация'), false, 'Текст локальной демонстрации должен отсутствовать');
  assert.equal(page.includes('supabase'), false, 'Все упоминания Supabase должны быть удалены');
  new vm.SourceTextModule(page.match(/<script type="module">([\s\S]*?)<\/script>/)[1]);
});
