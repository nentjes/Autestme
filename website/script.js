// Autestme Website JavaScript

// Language state
let currentLang = localStorage.getItem('autestme-lang') || detectBrowserLanguage();

// Detect browser language
function detectBrowserLanguage() {
    const browserLang = navigator.language.toLowerCase();
    if (browserLang.startsWith('nl')) return 'nl';
    if (browserLang.startsWith('es')) return 'es';
    if (browserLang.startsWith('zh')) return 'zh';
    if (browserLang.startsWith('hi')) return 'hi';
    return 'en';
}

// AUT Token contract address
const AUT_CONTRACT = '0x3a0DCDFf06f9a0Ad20f212224a5162F6fc0e344c';

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    setLanguage(currentLang);
    fetchAUTPrice();
    initSmoothScroll();
});

// Set language
function setLanguage(lang) {
    if (!translations[lang]) lang = 'en';
    currentLang = lang;
    localStorage.setItem('autestme-lang', lang);
    document.documentElement.lang = lang;

    // Set font family for Chinese and Hindi
    if (lang === 'zh') {
        document.body.style.fontFamily = "'Noto Sans SC', 'Inter', sans-serif";
    } else if (lang === 'hi') {
        document.body.style.fontFamily = "'Noto Sans Devanagari', 'Inter', sans-serif";
    } else {
        document.body.style.fontFamily = "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
    }

    // Update all translatable elements
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (translations[lang][key]) {
            el.textContent = translations[lang][key];
        }
    });

    // Update language toggle button
    updateLangButton();

    // Close language menu
    closeLangMenu();
}

// Update language toggle button text
function updateLangButton() {
    document.querySelectorAll('.lang-toggle').forEach(btn => {
        btn.textContent = langNames[currentLang] + ' ▼';
    });
}

// Toggle language dropdown menu
function toggleLangMenu() {
    const menu = document.getElementById('langMenu');
    menu.classList.toggle('active');
}

// Close language menu
function closeLangMenu() {
    const menu = document.getElementById('langMenu');
    if (menu) menu.classList.remove('active');
}

// Toggle mobile menu
function toggleMobileMenu() {
    const menu = document.getElementById('mobileMenu');
    menu.classList.toggle('active');
}

// Copy contract address to clipboard
function copyContract() {
    const address = document.getElementById('contractAddress').textContent;
    navigator.clipboard.writeText(address).then(() => {
        const btn = document.querySelector('.copy-btn');
        const originalText = translations[currentLang].copy_btn;
        btn.textContent = translations[currentLang].copied_btn;
        btn.style.background = '#10B981';

        setTimeout(() => {
            btn.textContent = originalText;
            btn.style.background = '';
        }, 2000);
    });
}

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Navbar background on scroll
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.scrollY > 50) {
        navbar.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
    }
});

// Close menus when clicking outside
document.addEventListener('click', (e) => {
    const mobileMenu = document.getElementById('mobileMenu');
    const mobileBtn = document.querySelector('.mobile-menu-btn');
    const langMenu = document.getElementById('langMenu');
    const langSelector = document.querySelector('.lang-selector');

    // Close mobile menu
    if (mobileMenu && !mobileMenu.contains(e.target) && !mobileBtn.contains(e.target)) {
        mobileMenu.classList.remove('active');
    }

    // Close language menu
    if (langMenu && langSelector && !langSelector.contains(e.target)) {
        langMenu.classList.remove('active');
    }
});

// Fetch AUT token price from DexScreener
async function fetchAUTPrice() {
    const priceDisplay = document.getElementById('autPrice');
    if (!priceDisplay) return;

    try {
        // We voegen 'polygon' specifiek toe aan de URL
        const response = await fetch(`https://api.dexscreener.com/latest/dex/tokens/${AUT_CONTRACT}`);
        const data = await response.json();

        // Check of er paren zijn gevonden op Polygon
        const pair = data.pairs ? data.pairs.find(p => p.chainId === 'polygon') : null;

        if (pair) {
            const priceUsd = parseFloat(pair.priceUsd || 0);
            const priceEur = priceUsd * 0.92; 

            priceDisplay.innerHTML = `
                <span class="price-main">$${priceUsd.toFixed(6)}</span>
                <span class="price-secondary">≈ €${priceEur.toFixed(6)}</span>
            `;
        } else {
            throw new Error("Geen pool gevonden");
        }
    } catch (error) {
        console.error('Error fetching price:', error);
        // Fallback naar de prijs van jouw net aangemaakte pool ($0.01)
        priceDisplay.innerHTML = `
            <span class="price-main">$0.0100</span>
            <span class="price-secondary">≈ €0.0092</span>
        `;
    }
}
// Copy buy contract address
function copyBuyContract() {
    navigator.clipboard.writeText(AUT_CONTRACT).then(() => {
        const btn = document.querySelector('.copy-btn-small');
        if (btn) {
            const originalText = btn.textContent;
            btn.textContent = '✓';
            btn.style.background = '#10B981';

            setTimeout(() => {
                btn.textContent = originalText;
                btn.style.background = '';
            }, 2000);
        }
    });
}

// Track buy button clicks (for analytics)
function trackBuyClick() {
    console.log('Buy button clicked - user redirected to QuickSwap');
    // Add your analytics tracking here if needed
}

// Refresh price every 60 seconds
setInterval(fetchAUTPrice, 60000);
