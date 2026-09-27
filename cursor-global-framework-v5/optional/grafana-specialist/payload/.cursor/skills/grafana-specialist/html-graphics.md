# HTML Graphics Panel Development

The HTML Graphics panel (`gapit-htmlgraphics-panel`) enables custom HTML, CSS, JavaScript, and SVG rendering driven by Grafana DataFrames. Grafana 12 emphasizes stricter Content Security Policy (CSP), theme token modernization, and Scenes-compatible component lifecycles.

## Lifecycle Separation: onInit vs onRender

To ensure high rendering performance and eliminate memory leaks on dashboards with frequent auto-refresh (e.g. 5s–10s NOC walls):

1. **`onInit({ htmlGraphics, options, theme })`**:
   - Executes **once** when the panel mounts or options change.
   - Use exclusively for static DOM/SVG skeleton construction, initial layout setup, attaching event listeners, and initializing state in `htmlGraphics.state`.
   - **Never** perform repetitive DOM recreation or heavy element destruction here.
   - Store persistent variables (timers, cache, persistent selections) strictly on `htmlGraphics.state`.
   - Clean up any window-level or external observers when panel re-initializes.

2. **`onRender({ data, options, theme, htmlGraphics })`**:
   - Executes **every time** new data arrives, time range changes, or manual refresh triggers.
   - **Never** rebuild the entire DOM tree via `container.innerHTML = ...` on every render. This causes DOM thrashing, visual flicker, high CPU usage, and garbage collection pauses.
   - Query existing elements cached or created in `onInit` and update attributes surgically (`setAttribute`, `classList.toggle`, `textContent`, SVG style attributes).
   - Check `data.series` length and structure before accessing fields to handle empty or loading states gracefully.

## Data Binding with Grafana DataFrames

Grafana data arrives as an array of DataFrames (`data.series`).
- Extract series and fields safely:
  ```javascript
  if (!data || !data.series || data.series.length === 0) return;
  const series = data.series[0];
  const timeField = series.fields.find(f => f.type === 'time');
  const valueField = series.fields.find(f => f.type === 'number');
  const latestValue = valueField && valueField.values.length > 0 
    ? valueField.values.get(valueField.values.length - 1) 
    : null;
  ```
- Support field overrides and thresholds (`field.thresholds` or `field.display(value)`). Format numbers and units using Grafana's built-in field display formatters when available.

## Scoped CSS and Styling

- Always scope CSS selectors under a unique wrapper class or ID (e.g. `.custom-htmlgraphics-panel`, `#htmlgraphics-container`) so custom rules never leak into Grafana's navigation, header, or peer panels.
- Avoid global resets (`* { margin: 0; }`).
- Use CSS variables for responsiveness and layout:
  ```css
  .htmlgraphics-wrapper {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    box-sizing: border-box;
  }
  ```

## Dynamic SVG and Responsive Design

- For network topologies, rack elevations, floor plans, and interactive architecture maps, use inline `<svg>` with `viewBox="0 0 W H"` and `preserveAspectRatio="xMidYMid meet"`.
- Apply status colors directly to SVG shapes (`fill`, `stroke`) using CSS classes or attribute updates rather than replacing the SVG DOM.
- Add SVG tooltips and micro-interactions with CSS transitions (`transition: fill 0.3s ease;`) to provide smooth visual feedback without CPU overhead.

## Theme Integration & Grafana 12 Compatibility

- Dynamically adapt to Grafana theme changes via `theme.isDark` or `theme.colors`:
  ```javascript
  const isDark = theme.isDark;
  const textColor = isDark ? '#d8d9da' : '#22252b';
  const bgColor = isDark ? 'rgba(30, 34, 42, 0.6)' : 'rgba(240, 242, 245, 0.8)';
  ```
- Respect Grafana 12 Content Security Policy: avoid `eval()`, inline event attributes (`onclick="..."` in HTML string), and untrusted remote script loading. Attach handlers programmatically in `onInit`.
