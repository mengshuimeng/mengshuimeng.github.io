// Run against a local Hugo preview with playwright-cli run-code --filename.
// Removing the luminous peak or the fade must fail this browser regression.
async (page) => {
  const results = [];
  try {
    for (const path of ['/', '/en/']) {
      await page.emulateMedia({ reducedMotion: 'no-preference' });
      await page.goto('http://127.0.0.1:1313' + path);
      const samples = await page.evaluate(() => {
        return ['.navbar-breathing-dot', '.home-breathing-dot'].map(selector => {
          const dot = document.querySelector(selector);
          const animation = dot?.getAnimations()[0];
          if (!animation || animation.playState !== 'running') {
            throw new Error(selector + ' has no running animation');
          }
          const duration = Number(animation.effect.getTiming().duration);
          animation.pause();
          const sample = time => {
            animation.currentTime = time;
            const style = getComputedStyle(dot);
            return { opacity: Number(style.opacity), shadow: style.boxShadow };
          };
          try {
            return { selector, dim: sample(0), bright: sample(duration / 2) };
          } finally {
            animation.play();
          }
        });
      });
      for (const sample of samples) {
        if (sample.bright.opacity - sample.dim.opacity < 0.3) {
          throw new Error(sample.selector + ' must visibly fade between phases');
        }
        const shadows = sample.bright.shadow.matchAll(/rgba?\(([^)]+)\)\s+([\d.-]+)px\s+([\d.-]+)px\s+([\d.-]+)px/g);
        const visibleGlow = [...shadows].some(match => {
          const channels = match[1].split(',').map(Number);
          const alpha = channels.length === 4 ? channels[3] : 1;
          return alpha >= 0.2 && Number(match[4]) >= 8;
        });
        if (!visibleGlow) {
          throw new Error(sample.selector + ' has no visible soft glow: ' + sample.bright.shadow);
        }
      }
      await page.emulateMedia({ reducedMotion: 'reduce' });
      const still = await page.evaluate(() => {
        return ['.navbar-breathing-dot', '.home-breathing-dot'].map(selector => {
          const dot = document.querySelector(selector);
          return { selector, animations: dot.getAnimations().length, opacity: Number(getComputedStyle(dot).opacity) };
        });
      });
      for (const light of still) {
        if (light.animations !== 0 || light.opacity < 0.5) {
          throw new Error(light.selector + ' must remain visible and stationary with reduced motion');
        }
      }
      results.push({ path, samples, reducedMotion: still });
    }
    return { passed: true, results };
  } finally {
    await page.emulateMedia({ reducedMotion: 'no-preference' });
  }
}
