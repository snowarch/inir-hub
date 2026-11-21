// Ejecutar desde la raíz del repo hub: node components/display-projection/tests/test_plan.js
'use strict';
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const PLAN_PATH = path.join(__dirname, '../state/plan.js');
const raw = fs.readFileSync(PLAN_PATH, 'utf8');
assert.equal(raw.split('\n')[0].trim(), '.pragma library', 'plan.js debe empezar por .pragma library');
const body = raw.split('\n').slice(1).join('\n');
const ctx = vm.createContext({});
const P = vm.runInContext(
  body + '\n;({ MODES, isInternal, parseOutputs, label, size, primary, externals, resolveTarget, parseMirrors, detectMode, plan, turnsOff });',
  ctx
);

// Los valores creados dentro del contexto vm tienen otros prototipos: normalizamos por JSON.
const J = (x) => JSON.parse(JSON.stringify(x));

// Fixture real de niri (ambas pantallas encendidas). HDMI va primero a propósito.
const REAL = JSON.stringify({
  'HDMI-A-1': { name: 'HDMI-A-1', make: 'Microstep', model: 'MAG 275CQ E18', serial: 'X', physical_size: [600, 340],
    modes: [
      { width: 1920, height: 1080, refresh_rate: 60000, is_preferred: false },
      { width: 2560, height: 1440, refresh_rate: 59951, is_preferred: true },
    ],
    current_mode: 1, vrr_supported: false, vrr_enabled: false,
    logical: { x: 1920, y: 0, width: 2560, height: 1440, scale: 1.0, transform: 'Normal' } },
  'eDP-1': { name: 'eDP-1', make: 'BOE', model: '0x0BCA', serial: null, physical_size: [340, 190],
    modes: [{ width: 1920, height: 1080, refresh_rate: 60008, is_preferred: true }],
    current_mode: 0, vrr_supported: false, vrr_enabled: false,
    logical: { x: 0, y: 0, width: 1920, height: 1080, scale: 1.0, transform: 'Normal' } },
});

const mode = (width, height, refresh_rate, is_preferred) => ({ width, height, refresh_rate, is_preferred });
const LOG = { x: 0, y: 0, width: 1, height: 1, scale: 1.0, transform: 'Normal' };

// Salida con la forma que devuelve parseOutputs
const D = (name, enabled, width = 1920, height = 1080) => ({ name, make: '', model: '', enabled, width, height });

describe('MODES', () => {
  test('lista exacta de modos', () => {
    assert.deepStrictEqual(J(P.MODES), ['pcOnly', 'duplicate', 'extend', 'secondOnly']);
  });
});

describe('isInternal', () => {
  test('paneles internos eDP, LVDS y DSI', () => {
    for (const n of ['eDP-1', 'LVDS-1', 'DSI-1']) assert.equal(P.isInternal(n), true, n);
  });
  test('externos y nombres que solo se parecen', () => {
    for (const n of ['HDMI-A-1', 'DP-2', '', 'xeDP-1']) assert.equal(P.isInternal(n), false, JSON.stringify(n));
  });
});

describe('parseOutputs', () => {
  test('fixture real: el interno va primero aunque HDMI esté antes en el JSON', () => {
    assert.deepStrictEqual(J(P.parseOutputs(REAL)), [
      { name: 'eDP-1', make: 'BOE', model: '0x0BCA', enabled: true, width: 1920, height: 1080 },
      { name: 'HDMI-A-1', make: 'Microstep', model: 'MAG 275CQ E18', enabled: true, width: 2560, height: 1440 },
    ]);
  });
  test('objeto vacío da lista vacía', () => {
    assert.deepStrictEqual(J(P.parseOutputs('{}')), []);
  });
  test('lanza si el JSON no es un objeto', () => {
    for (const t of ['[]', 'null', '3']) assert.throws(() => P.parseOutputs(t), undefined, t);
  });
  test('lanza si el texto no es JSON válido', () => {
    assert.throws(() => P.parseOutputs('{'));
  });
  test('enabled es false cuando logical es null o no existe', () => {
    const text = JSON.stringify({
      'eDP-1': { name: 'eDP-1', make: 'a', model: 'b', modes: [mode(1920, 1080, 60000, true)], current_mode: 0, logical: null },
      'DP-1': { name: 'DP-1', make: 'a', model: 'b', modes: [mode(1920, 1080, 60000, true)], current_mode: 0 },
    });
    const got = J(P.parseOutputs(text));
    assert.equal(got.find((o) => o.name === 'eDP-1').enabled, false);
    assert.equal(got.find((o) => o.name === 'DP-1').enabled, false);
  });
  test('con current_mode null usa el modo preferido', () => {
    const text = JSON.stringify({ 'DP-1': { name: 'DP-1', make: 'a', model: 'b',
      modes: [mode(1280, 720, 60000, false), mode(1920, 1080, 60000, true)], current_mode: null, logical: LOG } });
    const [o] = J(P.parseOutputs(text));
    assert.equal(o.width, 1920);
    assert.equal(o.height, 1080);
  });
  test('con current_mode null y sin preferido usa modes[0]', () => {
    const text = JSON.stringify({ 'DP-1': { name: 'DP-1', make: 'a', model: 'b',
      modes: [mode(1280, 720, 60000, false), mode(1920, 1080, 60000, false)], current_mode: null, logical: LOG } });
    const [o] = J(P.parseOutputs(text));
    assert.equal(o.width, 1280);
    assert.equal(o.height, 720);
  });
  test('sin modos da width y height 0', () => {
    const text = JSON.stringify({ 'DP-1': { name: 'DP-1', make: 'a', model: 'b', modes: [], current_mode: null, logical: null } });
    const [o] = J(P.parseOutputs(text));
    assert.equal(o.width, 0);
    assert.equal(o.height, 0);
  });
  test('orden: internos primero y el resto por nombre ascendente', () => {
    const text = JSON.stringify({
      'HDMI-A-2': { name: 'HDMI-A-2', make: 'a', model: 'b', modes: [mode(1920, 1080, 60000, true)], current_mode: 0, logical: LOG },
      'DP-1': { name: 'DP-1', make: 'a', model: 'b', modes: [mode(1920, 1080, 60000, true)], current_mode: 0, logical: LOG },
      'eDP-1': { name: 'eDP-1', make: 'a', model: 'b', modes: [mode(1920, 1080, 60000, true)], current_mode: 0, logical: LOG },
    });
    assert.deepStrictEqual(J(P.parseOutputs(text)).map((o) => o.name), ['eDP-1', 'DP-1', 'HDMI-A-2']);
  });
});

describe('label', () => {
  test('ejemplos de la especificación', () => {
    assert.equal(P.label({ name: 'eDP-1', model: '0x0BCA' }), 'eDP-1');
    assert.equal(P.label({ name: 'HDMI-A-1', model: 'MAG 275CQ E18' }), 'MAG 275CQ E18');
  });
  test('model vacío, que empieza por 0x, "Unknown" o solo espacios usa name', () => {
    for (const model of ['', '0x1234', 'Unknown', '   ']) {
      assert.equal(P.label({ name: 'DP-2', model }), 'DP-2', JSON.stringify(model));
    }
  });
  test('recorta espacios del model real', () => {
    assert.equal(P.label({ name: 'HDMI-A-1', model: '  MAG 275CQ E18  ' }), 'MAG 275CQ E18');
  });
});

describe('size', () => {
  test('formato W×H con U+00D7', () => {
    const s = P.size({ width: 2560, height: 1440 });
    assert.equal(s, '2560\xD71440');
  });
  test('cadena vacía si width o height es 0', () => {
    assert.equal(P.size({ width: 0, height: 1080 }), '');
    assert.equal(P.size({ width: 1920, height: 0 }), '');
    assert.equal(P.size({ width: 0, height: 0 }), '');
  });
});

describe('primary', () => {
  test('el primer interno', () => {
    assert.equal(P.primary([D('HDMI-A-1', true), D('eDP-1', true)]).name, 'eDP-1');
  });
  test('sin interno, la primera pantalla', () => {
    assert.equal(P.primary([D('DP-2', true), D('HDMI-A-1', true)]).name, 'DP-2');
  });
  test('null para lista vacía o undefined', () => {
    assert.equal(P.primary([]), null);
    assert.equal(P.primary(undefined), null);
  });
});

describe('externals', () => {
  test('todas menos la primaria', () => {
    const outs = [D('eDP-1', true), D('HDMI-A-1', true), D('DP-2', false)];
    assert.deepStrictEqual(J(P.externals(outs)).map((o) => o.name), ['HDMI-A-1', 'DP-2']);
  });
  test('sin interno, la primaria es la primera y se excluye', () => {
    const outs = [D('DP-2', true), D('HDMI-A-1', true)];
    assert.deepStrictEqual(J(P.externals(outs)).map((o) => o.name), ['HDMI-A-1']);
  });
  test('lista vacía da lista vacía', () => {
    assert.deepStrictEqual(J(P.externals([])), []);
  });
});

describe('resolveTarget', () => {
  const outs = [D('eDP-1', true), D('HDMI-A-1', true), D('DP-1', false)];
  test('devuelve el externo con ese nombre', () => {
    assert.equal(P.resolveTarget(outs, 'DP-1').name, 'DP-1');
  });
  test('nombre no encontrado o vacío devuelve el primer externo', () => {
    assert.equal(P.resolveTarget(outs, 'nope').name, 'HDMI-A-1');
    assert.equal(P.resolveTarget(outs, '').name, 'HDMI-A-1');
  });
  test('nunca devuelve la primaria aunque la pidan', () => {
    assert.equal(P.resolveTarget(outs, 'eDP-1').name, 'HDMI-A-1');
  });
  test('null cuando no hay externos o no hay pantallas', () => {
    assert.equal(P.resolveTarget([D('eDP-1', true)], 'eDP-1'), null);
    assert.equal(P.resolveTarget([], 'HDMI-A-1'), null);
  });
});

describe('parseMirrors', () => {
  test('ejemplo de la especificación', () => {
    assert.deepStrictEqual(
      J(P.parseMirrors('1234 wl-mirror --fullscreen-output HDMI-A-1 eDP-1\n99 wl-mirror eDP-1\n')),
      [{ pid: '1234', target: 'HDMI-A-1', source: 'eDP-1' }]
    );
  });
  test('forma corta -F toma el siguiente argumento como destino', () => {
    assert.deepStrictEqual(J(P.parseMirrors('55 wl-mirror -F DP-1 eDP-1')), [{ pid: '55', target: 'DP-1', source: 'eDP-1' }]);
  });
  test('--fullscreen y -f dan target vacío', () => {
    assert.deepStrictEqual(J(P.parseMirrors('77 wl-mirror --fullscreen eDP-1')), [{ pid: '77', target: '', source: 'eDP-1' }]);
    assert.deepStrictEqual(J(P.parseMirrors('78 wl-mirror -f eDP-1')), [{ pid: '78', target: '', source: 'eDP-1' }]);
  });
  test('source es "" si el último argumento empieza por guion', () => {
    assert.deepStrictEqual(J(P.parseMirrors('3 wl-mirror --fullscreen-output HDMI-A-1 --other')), [{ pid: '3', target: 'HDMI-A-1', source: '' }]);
  });
  test('ignora líneas sin pid numérico, vacías y sin flag de pantalla completa', () => {
    const text = [
      'wl-mirror eDP-1',
      'abc wl-mirror -F X Y',
      '',
      '5 wl-mirror eDP-1',
      '6 wl-mirror --fullscreen-output HDMI-A-1 eDP-1',
    ].join('\n');
    assert.deepStrictEqual(J(P.parseMirrors(text)), [{ pid: '6', target: 'HDMI-A-1', source: 'eDP-1' }]);
  });
  test('"" y undefined dan lista vacía', () => {
    assert.deepStrictEqual(J(P.parseMirrors('')), []);
    assert.deepStrictEqual(J(P.parseMirrors(undefined)), []);
  });
});

describe('detectMode', () => {
  test('sin salidas devuelve cadena vacía', () => {
    assert.equal(P.detectMode([], false), '');
  });
  test('pcOnly cuando ningún externo está encendido, también con una sola pantalla', () => {
    assert.equal(P.detectMode([D('eDP-1', true), D('HDMI-A-1', false)], false), 'pcOnly');
    assert.equal(P.detectMode([D('eDP-1', true)], false), 'pcOnly');
    assert.equal(P.detectMode([D('eDP-1', false), D('HDMI-A-1', false)], false), 'pcOnly');
  });
  test('secondOnly cuando el externo está encendido y la primaria apagada', () => {
    assert.equal(P.detectMode([D('eDP-1', false), D('HDMI-A-1', true)], false), 'secondOnly');
  });
  test('duplicate con ambas encendidas y mirroring; extend sin mirroring', () => {
    const both = [D('eDP-1', true), D('HDMI-A-1', true)];
    assert.equal(P.detectMode(both, true), 'duplicate');
    assert.equal(P.detectMode(both, false), 'extend');
  });
});

describe('plan', () => {
  const BOTH = [D('eDP-1', true), D('HDMI-A-1', true)];

  test('modo desconocido da error unknownMode', () => {
    assert.deepStrictEqual(J(P.plan('mirror', BOTH, '', [])), { error: 'unknownMode' });
    assert.deepStrictEqual(J(P.plan('', BOTH, '', [])), { error: 'unknownMode' });
  });
  test('sin pantallas da error noDisplays', () => {
    assert.deepStrictEqual(J(P.plan('pcOnly', [], '', [])), { error: 'noDisplays' });
  });
  test('duplicate, extend y secondOnly sin externo dan noSecond', () => {
    const only = [D('eDP-1', true)];
    for (const m of ['duplicate', 'extend', 'secondOnly']) {
      assert.deepStrictEqual(J(P.plan(m, only, '', [])), { error: 'noSecond' }, m);
    }
  });
  test('pcOnly con solo la primaria funciona y no hace nada si ya está encendida', () => {
    assert.deepStrictEqual(J(P.plan('pcOnly', [D('eDP-1', true)], '', [])), { steps: [] });
  });
  test('pcOnly con solo la primaria apagada la enciende', () => {
    assert.deepStrictEqual(J(P.plan('pcOnly', [D('eDP-1', false)], '', [])), { steps: [{ kind: 'on', name: 'eDP-1' }] });
  });

  test('ejemplos de la especificación con eDP-1 y HDMI-A-1 encendidos, sin mirrors', () => {
    assert.deepStrictEqual(J(P.plan('pcOnly', BOTH, '', [])).steps, [{ kind: 'off', name: 'HDMI-A-1' }]);
    assert.deepStrictEqual(J(P.plan('extend', BOTH, '', [])).steps, []);
    assert.deepStrictEqual(J(P.plan('duplicate', BOTH, '', [])).steps, [
      { kind: 'wait', name: 'HDMI-A-1' },
      { kind: 'mirror', source: 'eDP-1', target: 'HDMI-A-1' },
    ]);
    assert.deepStrictEqual(J(P.plan('secondOnly', BOTH, '', [])).steps, [{ kind: 'off', name: 'eDP-1' }]);
  });

  test('secondOnly con mirrors: on(target), stop, off(primary)', () => {
    const outs = [D('eDP-1', true), D('HDMI-A-1', false)];
    assert.deepStrictEqual(J(P.plan('secondOnly', outs, '', [{ pid: '7' }])).steps, [
      { kind: 'on', name: 'HDMI-A-1' },
      { kind: 'stop', pids: ['7'] },
      { kind: 'off', name: 'eDP-1' },
    ]);
  });

  test('tres pantallas: requested decide el destino de extend', () => {
    const outs = [D('eDP-1', true), D('DP-1', false), D('HDMI-A-1', false)];
    assert.deepStrictEqual(J(P.plan('extend', outs, 'HDMI-A-1', [])).steps, [{ kind: 'on', name: 'HDMI-A-1' }]);
    assert.deepStrictEqual(J(P.plan('extend', outs, 'nope', [])).steps, [{ kind: 'on', name: 'DP-1' }]);
  });

  test('pcOnly: on(primary), stop, luego off de cada externo en orden de externals', () => {
    const outs = [D('eDP-1', false), D('DP-1', true), D('HDMI-A-1', true)];
    assert.deepStrictEqual(J(P.plan('pcOnly', outs, '', [{ pid: '1' }, { pid: '2' }])).steps, [
      { kind: 'on', name: 'eDP-1' },
      { kind: 'stop', pids: ['1', '2'] },
      { kind: 'off', name: 'DP-1' },
      { kind: 'off', name: 'HDMI-A-1' },
    ]);
  });

  test('pcOnly no toca externos ya apagados', () => {
    const outs = [D('eDP-1', true), D('DP-1', false), D('HDMI-A-1', true)];
    assert.deepStrictEqual(J(P.plan('pcOnly', outs, '', [])).steps, [{ kind: 'off', name: 'HDMI-A-1' }]);
  });

  test('secondOnly deja los otros externos como estaban', () => {
    const outs = [D('eDP-1', true), D('DP-1', true), D('HDMI-A-1', false)];
    const steps = J(P.plan('secondOnly', outs, 'HDMI-A-1', [])).steps;
    assert.deepStrictEqual(steps, [{ kind: 'on', name: 'HDMI-A-1' }, { kind: 'off', name: 'eDP-1' }]);
    assert.ok(!steps.some((s) => s.name === 'DP-1'));
  });

  test('extend con la primaria apagada solo la enciende', () => {
    const outs = [D('eDP-1', false), D('HDMI-A-1', true)];
    assert.deepStrictEqual(J(P.plan('extend', outs, '', [])).steps, [{ kind: 'on', name: 'eDP-1' }]);
  });

  test('extend con mirrors emite solo stop', () => {
    assert.deepStrictEqual(J(P.plan('extend', BOTH, '', [{ pid: '3' }])).steps, [{ kind: 'stop', pids: ['3'] }]);
  });

  test('mirrors vacío no emite stop', () => {
    assert.deepStrictEqual(J(P.plan('extend', BOTH, '', [])).steps, []);
    assert.deepStrictEqual(J(P.plan('pcOnly', BOTH, '', undefined)).steps, [{ kind: 'off', name: 'HDMI-A-1' }]);
  });

  test('duplicate con mirrors: on(target), stop, wait, mirror', () => {
    const outs = [D('eDP-1', true), D('HDMI-A-1', false)];
    assert.deepStrictEqual(J(P.plan('duplicate', outs, 'HDMI-A-1', [{ pid: '9' }])).steps, [
      { kind: 'on', name: 'HDMI-A-1' },
      { kind: 'stop', pids: ['9'] },
      { kind: 'wait', name: 'HDMI-A-1' },
      { kind: 'mirror', source: 'eDP-1', target: 'HDMI-A-1' },
    ]);
  });

  test('invariantes en todos los modos: on solo para apagadas, off solo para encendidas, todo on antes que off', () => {
    const scenarios = [
      [D('eDP-1', true), D('HDMI-A-1', false)],
      [D('eDP-1', false), D('HDMI-A-1', true)],
      [D('eDP-1', true), D('DP-1', true), D('HDMI-A-1', true)],
      [D('eDP-1', false), D('DP-1', false), D('HDMI-A-1', true)],
    ];
    const mirrorSets = [[], [{ pid: '1' }]];
    for (const m of ['pcOnly', 'extend', 'secondOnly', 'duplicate']) {
      for (const outs of scenarios) {
        for (const mirrors of mirrorSets) {
          const res = J(P.plan(m, outs, '', mirrors));
          const info = m + ' ' + JSON.stringify(outs.map((o) => [o.name, o.enabled])) + ' mirrors=' + mirrors.length;
          assert.ok(Array.isArray(res.steps), info);
          const byName = Object.fromEntries(outs.map((o) => [o.name, o.enabled]));
          res.steps.forEach((s) => {
            if (s.kind === 'on') assert.equal(byName[s.name], false, 'on sobre encendida: ' + info);
            if (s.kind === 'off') assert.equal(byName[s.name], true, 'off sobre apagada: ' + info);
          });
          const lastOn = Math.max(-1, ...res.steps.map((s, i) => (s.kind === 'on' ? i : -1)));
          const firstOff = res.steps.findIndex((s) => s.kind === 'off');
          if (firstOff !== -1) assert.ok(lastOn < firstOff, 'on después de off: ' + info);
          const stops = res.steps.filter((s) => s.kind === 'stop');
          assert.equal(stops.length, mirrors.length ? 1 : 0, 'stop: ' + info);
          if (stops.length) assert.deepStrictEqual(stops[0].pids, mirrors.map((x) => x.pid), 'pids: ' + info);
        }
      }
    }
  });
});

describe('turnsOff', () => {
  test('true si hay un off para ese nombre', () => {
    assert.equal(P.turnsOff([{ kind: 'off', name: 'eDP-1' }], 'eDP-1'), true);
  });
  test('false para on, wait, otro nombre, lista vacía o undefined', () => {
    assert.equal(P.turnsOff([{ kind: 'on', name: 'HDMI-A-1' }], 'HDMI-A-1'), false);
    assert.equal(P.turnsOff([{ kind: 'wait', name: 'HDMI-A-1' }], 'HDMI-A-1'), false);
    assert.equal(P.turnsOff([{ kind: 'off', name: 'HDMI-A-1' }], 'eDP-1'), false);
    assert.equal(P.turnsOff([], 'eDP-1'), false);
    assert.equal(P.turnsOff(undefined, 'eDP-1'), false);
  });
  test('el nombre debe coincidir exactamente', () => {
    assert.equal(P.turnsOff([{ kind: 'off', name: 'HDMI-A-1' }], 'HDMI'), false);
  });
});
