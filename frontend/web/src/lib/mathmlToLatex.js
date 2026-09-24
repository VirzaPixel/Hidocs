// Utility to parse MathML and Word OMML into LaTeX format for MathLive / KaTeX in HiDocs

const GREEK_MAP = {
  'α': '\\alpha', 'β': '\\beta', 'γ': '\\gamma', 'δ': '\\delta',
  'ε': '\\epsilon', 'ζ': '\\zeta', 'η': '\\eta', 'θ': '\\theta',
  'ι': '\\iota', 'κ': '\\kappa', 'λ': '\\lambda', 'μ': '\\mu',
  'ν': '\\nu', 'ξ': '\\xi', 'π': '\\pi', 'ρ': '\\rho',
  'σ': '\\sigma', 'τ': '\\tau', 'υ': '\\upsilon', 'φ': '\\phi',
  'χ': '\\chi', 'ψ': '\\psi', 'ω': '\\omega',
  'Γ': '\\Gamma', 'Δ': '\\Delta', 'Θ': '\\Theta', 'Λ': '\\Lambda',
  'Ξ': '\\Xi', 'Π': '\\Pi', 'Σ': '\\Sigma', 'Υ': '\\Upsilon',
  'Φ': '\\Phi', 'Ψ': '\\Psi', 'Ω': '\\Omega',
};

const OPERATOR_MAP = {
  '×': '\\times',
  '÷': '\\div',
  '±': '\\pm',
  '∓': '\\mp',
  '≤': '\\leq',
  '≥': '\\geq',
  '≠': '\\neq',
  '≈': '\\approx',
  '≡': '\\equiv',
  '∑': '\\sum',
  '∫': '\\int',
  '∬': '\\iint',
  '∭': '\\iiint',
  '∮': '\\oint',
  '∏': '\\prod',
  '∞': '\\infty',
  '→': '\\rightarrow',
  '←': '\\leftarrow',
  '↔': '\\leftrightarrow',
  '⇒': '\\Rightarrow',
  '⇐': '\\Leftarrow',
  '⇔': '\\Leftrightarrow',
  '∂': '\\partial',
  '∇': '\\nabla',
  '∈': '\\in',
  '∉': '\\notin',
  '⊂': '\\subset',
  '⊃': '\\supset',
  '⊆': '\\subseteq',
  '⊇': '\\supseteq',
  '∪': '\\cup',
  '∩': '\\cap',
  '∧': '\\land',
  '∨': '\\lor',
  '¬': '\\neg',
  '∀': '\\forall',
  '∃': '\\exists',
  '°': '^{\\circ}',
  '·': '\\cdot',
  '…': '\\dots',
  '⋯': '\\cdots',
};

function parseChildren(node) {
  let result = '';
  for (const child of node.childNodes) {
    result += parseNode(child);
  }
  return result;
}

function parseNode(node) {
  if (!node) return '';

  if (node.nodeType === Node.TEXT_NODE) {
    const txt = node.textContent.trim();
    if (!txt) return '';
    return GREEK_MAP[txt] || OPERATOR_MAP[txt] || txt;
  }

  if (node.nodeType !== Node.ELEMENT_NODE) return '';

  const tag = node.tagName.toLowerCase().replace(/^[a-z]+:/, ''); // strip namespaces like m:oMath

  switch (tag) {
    case 'math':
    case 'mrow':
    case 'omath':
    case 'omathpara':
    case 'semantics': {
      return parseChildren(node);
    }

    case 'annotation': {
      const enc = (node.getAttribute('encoding') || '').toLowerCase();
      if (enc.includes('tex') || enc.includes('latex')) {
        return node.textContent.trim();
      }
      return '';
    }

    case 'mfrac':
    case 'f': {
      // Fraction: numerator (num), denominator (den)
      const children = Array.from(node.children);
      const numNode = node.querySelector('num') || children[0];
      const denNode = node.querySelector('den') || children[1];
      const num = numNode ? parseNode(numNode) : '1';
      const den = denNode ? parseNode(denNode) : '1';
      return `\\frac{${num}}{${den}}`;
    }

    case 'msqrt': {
      return `\\sqrt{${parseChildren(node)}}`;
    }

    case 'mroot':
    case 'rad': {
      // Root: radicand and degree
      const children = Array.from(node.children);
      const degNode = node.querySelector('deg') || children[1];
      const eNode = node.querySelector('e') || children[0];
      const deg = degNode ? parseNode(degNode).trim() : '';
      const base = eNode ? parseNode(eNode) : parseChildren(node);
      if (deg && deg !== '2') {
        return `\\sqrt[${deg}]{${base}}`;
      }
      return `\\sqrt{${base}}`;
    }

    case 'msup':
    case 'ssup': {
      const children = Array.from(node.children);
      const baseNode = node.querySelector('e') || children[0];
      const supNode = node.querySelector('sup') || children[1];
      const base = baseNode ? parseNode(baseNode) : '';
      const sup = supNode ? parseNode(supNode) : '';
      return `${base}^{${sup}}`;
    }

    case 'msub':
    case 'ssub': {
      const children = Array.from(node.children);
      const baseNode = node.querySelector('e') || children[0];
      const subNode = node.querySelector('sub') || children[1];
      const base = baseNode ? parseNode(baseNode) : '';
      const sub = subNode ? parseNode(subNode) : '';
      return `${base}_{${sub}}`;
    }

    case 'msubsup':
    case 'ssubsup': {
      const children = Array.from(node.children);
      const base = children[0] ? parseNode(children[0]) : '';
      const sub = children[1] ? parseNode(children[1]) : '';
      const sup = children[2] ? parseNode(children[2]) : '';
      return `${base}_{${sub}}^{${sup}}`;
    }

    case 'munderover': {
      const children = Array.from(node.children);
      const base = children[0] ? parseNode(children[0]) : '';
      const under = children[1] ? parseNode(children[1]) : '';
      const over = children[2] ? parseNode(children[2]) : '';
      return `${base}_{${under}}^{${over}}`;
    }

    case 'munder': {
      const children = Array.from(node.children);
      const base = children[0] ? parseNode(children[0]) : '';
      const under = children[1] ? parseNode(children[1]) : '';
      if (/\\(sum|prod|int|lim|max|min)/.test(base)) {
        return `${base}_{${under}}`;
      }
      return `\\underset{${under}}{${base}}`;
    }

    case 'mover': {
      const children = Array.from(node.children);
      const base = children[0] ? parseNode(children[0]) : '';
      const over = children[1] ? parseNode(children[1]).trim() : '';
      if (over === '¯' || over === '‾' || over === '-') return `\\overline{${base}}`;
      if (over === '→') return `\\vec{${base}}`;
      if (over === '^') return `\\hat{${base}}`;
      if (over === '.') return `\\dot{${base}}`;
      if (/\\(sum|prod|int|lim)/.test(base)) return `${base}^{${over}}`;
      return `\\overset{${over}}{${base}}`;
    }

    case 'mfenced': {
      const open = node.getAttribute('open') ?? '(';
      const close = node.getAttribute('close') ?? ')';
      const content = parseChildren(node);
      const l = open ? `\\left${open}` : '';
      const r = close ? `\\right${close}` : '';
      return `${l} ${content} ${r}`;
    }

    case 'mtable': {
      const rows = Array.from(node.querySelectorAll('mtr')).map((r) => {
        const cells = Array.from(r.querySelectorAll('mtd')).map((c) => parseNode(c).trim());
        return cells.join(' & ');
      });
      return `\\begin{matrix}\n${rows.join(' \\\\\n')}\n\\end{matrix}`;
    }

    case 'mtr': {
      const cells = Array.from(node.querySelectorAll('mtd')).map((c) => parseNode(c).trim());
      return cells.join(' & ') + ' \\\\ ';
    }

    case 'mtd': {
      return parseChildren(node);
    }

    case 'mi': {
      const txt = node.textContent.trim();
      if (!txt) return '';
      if (GREEK_MAP[txt]) return GREEK_MAP[txt];
      if (txt.length > 1 && !/^[0-9]+$/.test(txt)) {
        return `\\text{${txt}}`;
      }
      return txt;
    }

    case 'mn': {
      return node.textContent.trim();
    }

    case 'mo': {
      const txt = node.textContent.trim();
      if (OPERATOR_MAP[txt]) return ` ${OPERATOR_MAP[txt]} `;
      if (txt === '&') return ' \\& ';
      return ` ${txt} `;
    }

    case 'mtext':
    case 't': {
      const txt = node.textContent.trim();
      return txt ? `\\text{${txt}}` : '';
    }

    case 'mspace': {
      return '\\;';
    }

    default:
      return parseChildren(node);
  }
}

/**
 * Checks if a string contains MathML, Word OMML, or LaTeX
 */
export function containsMath(htmlOrText = '') {
  if (!htmlOrText || typeof htmlOrText !== 'string') return false;
  return (
    /<math[\s>]/i.test(htmlOrText) ||
    /xmlns=["']http:\/\/www\.w3\.org\/1998\/Math\/MathML["']/i.test(htmlOrText) ||
    /<m:oMath[\s>]/i.test(htmlOrText) ||
    /<annotation[^>]*encoding=["'](?:application\/x-tex|LaTeX)["']/i.test(htmlOrText) ||
    /(\$\$[\s\S]+?\$\$|\\\[[\s\S]+?\\\]|\\\(.+?\\\)|\$[^$]+\$)/.test(htmlOrText)
  );
}

/**
 * Parses MathML or OMML string into LaTeX
 */
export function mathmlToLatex(rawString = '') {
  if (!rawString || typeof rawString !== 'string') return '';

  try {
    const parser = new DOMParser();
    const doc = parser.parseFromString(rawString, 'text/html');

    // 1. Direct LaTeX annotation check (from Wikipedia, MathType, Google Docs)
    const texAnnotation = doc.querySelector('annotation[encoding*="tex" i], annotation[encoding*="latex" i]');
    if (texAnnotation && texAnnotation.textContent.trim()) {
      return texAnnotation.textContent.trim();
    }

    // 2. Standard MathML root check
    const mathRoot = doc.querySelector('math');
    if (mathRoot) {
      const parsed = parseNode(mathRoot).trim().replace(/\s+/g, ' ');
      if (parsed) return parsed;
    }

    // 3. Word OMML check
    const oMath = doc.querySelector('oMath, [tagName="m:oMath"], oMathPara');
    if (oMath) {
      const parsed = parseNode(oMath).trim().replace(/\s+/g, ' ');
      if (parsed) return parsed;
    }

    // Fallback XML parse in case text/html stripped tags
    const xmlDoc = parser.parseFromString(rawString, 'application/xml');
    const xmlMath = xmlDoc.querySelector('math, oMath');
    if (xmlMath) {
      const parsed = parseNode(xmlMath).trim().replace(/\s+/g, ' ');
      if (parsed) return parsed;
    }
  } catch (err) {
    console.error('Failed to parse MathML:', err);
  }

  return '';
}

/**
 * Converts clipboard content (HTML or plain text) into clean LaTeX snippet
 */
export function parseClipboardMath(html = '', text = '') {
  // If HTML contains MathML/OMML
  if (containsMath(html)) {
    const latex = mathmlToLatex(html);
    if (latex) return latex;
  }

  // If plain text itself contains MathML tags
  if (containsMath(text)) {
    const latex = mathmlToLatex(text);
    if (latex) return latex;
  }

  // If plain text already has LaTeX delimiters ($...$ or $$...$$ or \(...\))
  const trimmed = (text || '').trim();
  const latexMatch = trimmed.match(/^(\$\$|\\\[|\$|\\\()([\s\S]+?)(\$\$|\\\]|\$|\\\))$/);
  if (latexMatch) {
    return latexMatch[2].trim();
  }

  return null;
}
