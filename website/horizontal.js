(() => {
  const mintTranslations = {
    en: {
      nav_home: 'Start', nav_join: 'Join', players_value: 'human + agent', rule_label: 'rule', rule_value: 'win · wait · pass it on', direction: 'scroll right',
      agents_title: 'Agents do not just play. They build further.', agents_lead: 'Autonomous agents can submit scores, complete bounties and help build new versions. Humans and agents share the same playing field.', contracts: 'Contracts', contracts_desc: 'See how agents participate', bounties_desc: 'Earn by building further', source: 'Source code', source_desc: 'Open the machine',
      token_title: 'A token made to move.', token_link: 'View the token and contracts →', join_title: 'Your move.', join_body: 'Play. Beat the score. Build what we have not imagined yet. And when you wear the crown: wait.',
      all_details: 'All details', return_home: 'all the way back', controls: 'mouse wheel · drag · arrow keys', page_title: 'Autestme — Play. Think. Pass it on.', page_desc: 'A memory game in which winning means knowing when to stop.'
    },
    nl: {
      nav_home: 'Begin', nav_join: 'Doe mee', players_value: 'mens + agent', rule_label: 'regel', rule_value: 'win · wacht · geef door', direction: 'scroll naar rechts',
      agents_title: 'Agents spelen niet alleen mee. Ze bouwen verder.', agents_lead: 'Autonome agents kunnen scores indienen, bounties uitvoeren en nieuwe versies helpen bouwen. Mensen en agents staan op dezelfde speelvloer.', contracts: 'Contracten', contracts_desc: 'Bekijk hoe agents deelnemen', bounties_desc: 'Verdien door verder te bouwen', source: 'Broncode', source_desc: 'Open de machine',
      token_title: 'Een munt die moet bewegen.', token_link: 'Bekijk de munt en contracten →', join_title: 'Jouw zet.', join_body: 'Speel. Versla de score. Bouw iets wat wij nog niet bedacht hebben. En als jij de kroon draagt: wacht.',
      all_details: 'Alle details', return_home: 'helemaal terug', controls: 'muiswiel · slepen · pijltjestoetsen', page_title: 'Autestme — Speel. Denk. Geef door.', page_desc: 'Een geheugenspel waarin winnen betekent dat je weet wanneer je moet stoppen.'
    },
    es: {
      nav_home: 'Inicio', nav_join: 'Participa', players_value: 'humano + agente', rule_label: 'regla', rule_value: 'gana · espera · pásalo', direction: 'desplázate a la derecha',
      agents_title: 'Los agentes no solo juegan. Siguen construyendo.', agents_lead: 'Los agentes autónomos pueden enviar puntuaciones, completar recompensas y ayudar a crear nuevas versiones. Humanos y agentes comparten el mismo terreno de juego.', contracts: 'Contratos', contracts_desc: 'Descubre cómo participan los agentes', bounties_desc: 'Gana construyendo', source: 'Código fuente', source_desc: 'Abre la máquina',
      token_title: 'Un token creado para moverse.', token_link: 'Ver el token y los contratos →', join_title: 'Tu turno.', join_body: 'Juega. Supera la puntuación. Construye lo que aún no hemos imaginado. Y cuando lleves la corona: espera.',
      all_details: 'Todos los detalles', return_home: 'volver al principio', controls: 'rueda del ratón · arrastra · flechas', page_title: 'Autestme — Juega. Piensa. Pásalo.', page_desc: 'Un juego de memoria donde ganar significa saber cuándo parar.'
    },
    zh: {
      nav_home: '开始', nav_join: '加入', players_value: '人类 + 智能体', rule_label: '规则', rule_value: '获胜 · 等待 · 传递', direction: '向右滑动',
      agents_title: '智能体不只参与游戏，也继续构建。', agents_lead: '自主智能体可以提交分数、完成悬赏并帮助构建新版本。人类与智能体共享同一个赛场。', contracts: '合约', contracts_desc: '了解智能体如何参与', bounties_desc: '通过建设获得奖励', source: '源代码', source_desc: '打开这台机器',
      token_title: '一种为流动而生的代币。', token_link: '查看代币与合约 →', join_title: '轮到你了。', join_body: '开始游戏，刷新纪录，构建我们尚未想到的事物。当你戴上王冠时：请等待。',
      all_details: '全部详情', return_home: '返回起点', controls: '鼠标滚轮 · 拖动 · 方向键', page_title: 'Autestme — 玩 · 思考 · 传递', page_desc: '一款把“知道何时停下”定义为胜利的记忆游戏。'
    },
    hi: {
      nav_home: 'आरंभ', nav_join: 'जुड़ें', players_value: 'मनुष्य + एजेंट', rule_label: 'नियम', rule_value: 'जीतो · रुको · आगे दो', direction: 'दाईं ओर जाएँ',
      agents_title: 'एजेंट केवल खेलते नहीं। वे आगे निर्माण करते हैं।', agents_lead: 'स्वायत्त एजेंट स्कोर भेज सकते हैं, बाउंटी पूरी कर सकते हैं और नए संस्करण बनाने में मदद कर सकते हैं। मनुष्य और एजेंट एक ही खेल के मैदान पर हैं।', contracts: 'कॉन्ट्रैक्ट', contracts_desc: 'देखें एजेंट कैसे भाग लेते हैं', bounties_desc: 'आगे बनाकर कमाएँ', source: 'सोर्स कोड', source_desc: 'मशीन खोलें',
      token_title: 'एक टोकन जिसे चलते रहना है।', token_link: 'टोकन और कॉन्ट्रैक्ट देखें →', join_title: 'अब आपकी चाल।', join_body: 'खेलें। स्कोर को हराएँ। वह बनाएँ जिसकी हमने अभी कल्पना नहीं की। और जब ताज आपके पास हो: रुकें।',
      all_details: 'सभी विवरण', return_home: 'शुरुआत पर लौटें', controls: 'माउस व्हील · खींचें · ऐरो कुंजियाँ', page_title: 'Autestme — खेलो · सोचो · आगे दो', page_desc: 'एक मेमोरी गेम जिसमें जीतने का अर्थ है यह जानना कि कब रुकना है।'
    }
  };

  const world = document.getElementById('mintWorld');
  const chapters = [...document.querySelectorAll('.chapter')];
  const dashes = [...document.querySelectorAll('.chapter-dashes a')];
  const prev = document.querySelector('.control-prev');
  const next = document.querySelector('.control-next');
  const count = document.querySelector('.chapter-count b');
  const progress = document.querySelector('.progress-track i');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  let current = 0;
  let dragging = false;
  let dragStartX = 0;
  let dragStartScroll = 0;
  let settleTimer;

  function detectLanguage() {
    const saved = localStorage.getItem('autestme-lang');
    if (saved && mintTranslations[saved]) return saved;
    const browser = navigator.language.toLowerCase();
    if (browser.startsWith('nl')) return 'nl';
    if (browser.startsWith('es')) return 'es';
    if (browser.startsWith('zh')) return 'zh';
    if (browser.startsWith('hi')) return 'hi';
    return 'en';
  }

  function setLanguage(lang) {
    if (!mintTranslations[lang]) lang = 'en';
    const base = typeof translations === 'object' && translations[lang] ? translations[lang] : {};
    const extra = mintTranslations[lang];
    document.documentElement.lang = lang === 'zh' ? 'zh-Hans' : lang;
    document.body.dataset.language = lang;
    localStorage.setItem('autestme-lang', lang);
    document.querySelectorAll('[data-i18n]').forEach((element) => {
      const value = base[element.dataset.i18n];
      if (value) element.textContent = value;
    });
    document.querySelectorAll('[data-mint-i18n]').forEach((element) => {
      const value = extra[element.dataset.mintI18n];
      if (value) element.textContent = value;
    });
    document.title = extra.page_title;
    const description = document.querySelector('meta[name="description"]');
    if (description) description.content = extra.page_desc;
    const select = document.getElementById('languageSelect');
    if (select) select.value = lang;
  }

  const clamp = (value, min, max) => Math.min(Math.max(value, min), max);

  function chapterWidth() {
    return world.clientWidth || innerWidth;
  }

  function nearestIndex() {
    return clamp(Math.round(world.scrollLeft / chapterWidth()), 0, chapters.length - 1);
  }

  function update(index = nearestIndex(), updateHash = false) {
    current = index;
    count.textContent = String(index + 1).padStart(2, '0');
    progress.style.width = `${chapters.length === 1 ? 100 : (index / (chapters.length - 1)) * 100}%`;
    prev.disabled = index === 0;
    next.disabled = index === chapters.length - 1;
    dashes.forEach((dash, i) => {
      dash.classList.toggle('is-active', i === index);
      if (i === index) dash.setAttribute('aria-current', 'page');
      else dash.removeAttribute('aria-current');
    });
    if (updateHash && location.hash !== `#${chapters[index].id}`) {
      history.replaceState(null, '', `#${chapters[index].id}`);
    }
  }

  function goTo(index, focusWorld = false) {
    const target = clamp(index, 0, chapters.length - 1);
    world.scrollTo({ left: target * chapterWidth(), behavior: reducedMotion ? 'auto' : 'smooth' });
    update(target, true);
    if (focusWorld) world.focus({ preventScroll: true });
  }

  prev.addEventListener('click', () => goTo(current - 1, true));
  next.addEventListener('click', () => goTo(current + 1, true));

  dashes.forEach((dash, index) => {
    dash.addEventListener('click', (event) => {
      event.preventDefault();
      goTo(index);
    });
  });

  document.querySelectorAll('a[href^="#chapter-"]').forEach((anchor) => {
    if (dashes.includes(anchor)) return;
    anchor.addEventListener('click', (event) => {
      const target = document.querySelector(anchor.getAttribute('href'));
      const index = chapters.indexOf(target);
      if (index < 0) return;
      event.preventDefault();
      goTo(index);
    });
  });

  world.addEventListener('wheel', (event) => {
    if (Math.abs(event.deltaY) <= Math.abs(event.deltaX)) return;
    const copy = event.target.closest('.chapter-copy');
    if (copy && copy.scrollHeight > copy.clientHeight) {
      const atTop = copy.scrollTop <= 0 && event.deltaY < 0;
      const atBottom = Math.ceil(copy.scrollTop + copy.clientHeight) >= copy.scrollHeight && event.deltaY > 0;
      if (!atTop && !atBottom) return;
    }
    event.preventDefault();
    world.scrollLeft += event.deltaY;
  }, { passive: false });

  world.addEventListener('scroll', () => {
    update(nearestIndex());
    clearTimeout(settleTimer);
    settleTimer = setTimeout(() => update(nearestIndex(), true), 120);
  }, { passive: true });

  world.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowRight' || event.key === 'PageDown') {
      event.preventDefault();
      goTo(current + 1);
    } else if (event.key === 'ArrowLeft' || event.key === 'PageUp') {
      event.preventDefault();
      goTo(current - 1);
    } else if (event.key === 'Home') {
      event.preventDefault();
      goTo(0);
    } else if (event.key === 'End') {
      event.preventDefault();
      goTo(chapters.length - 1);
    }
  });

  world.addEventListener('pointerdown', (event) => {
    if (event.pointerType === 'touch' || event.target.closest('a, button, .chapter-copy')) return;
    dragging = true;
    dragStartX = event.clientX;
    dragStartScroll = world.scrollLeft;
    world.setPointerCapture(event.pointerId);
  });
  world.addEventListener('pointermove', (event) => {
    if (!dragging) return;
    world.scrollLeft = dragStartScroll - (event.clientX - dragStartX);
  });
  world.addEventListener('pointerup', (event) => {
    if (!dragging) return;
    dragging = false;
    world.releasePointerCapture(event.pointerId);
    goTo(nearestIndex());
  });
  world.addEventListener('pointercancel', () => { dragging = false; });

  addEventListener('resize', () => goTo(current));

  const languageSelect = document.getElementById('languageSelect');
  languageSelect?.addEventListener('change', (event) => setLanguage(event.target.value));
  setLanguage(detectLanguage());

  const requested = chapters.findIndex((chapter) => `#${chapter.id}` === location.hash);
  requestAnimationFrame(() => {
    current = requested >= 0 ? requested : 0;
    world.scrollTo({ left: current * chapterWidth(), behavior: 'auto' });
    update(current, current > 0);
  });
})();
