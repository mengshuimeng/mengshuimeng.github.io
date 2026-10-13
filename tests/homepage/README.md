# Homepage browser regression

Start the local preview with Hugo Extended 0.164.0:

```powershell
hugo server --disableFastRender -p 1313 --bind 127.0.0.1
```

In another terminal, use Playwright CLI and an installed Edge browser:

```powershell
npx --yes --package @playwright/cli playwright-cli -s=homepage open http://127.0.0.1:1313/ --browser=msedge
npx --yes --package @playwright/cli playwright-cli -s=homepage run-code --filename=tests/homepage/breathing-light.js
npx --yes --package @playwright/cli playwright-cli -s=homepage close
```

The regression samples the rendered light at its dim and bright phases. It
requires a visible brightness difference, a soft glow at the bright phase,
and a stationary visible light when reduced motion is enabled. Both the
navigation and homepage lights are checked on both language variants.
