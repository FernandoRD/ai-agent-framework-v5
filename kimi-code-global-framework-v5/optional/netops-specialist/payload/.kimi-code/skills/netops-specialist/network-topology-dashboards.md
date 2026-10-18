# Topologias Visuais de Rede no Grafana (HTML Graphics)

## 1. Modelagem do Mapa SVG

Estruture o SVG com identificadores claros para cada elemento interativo:
```html
<svg viewBox="0 0 1000 600" class="network-map">
  <!-- Enlaces (Links) -->
  <line id="link-core-distrib" x1="200" y1="300" x2="500" y2="300" stroke="#4ade80" stroke-width="4" />
  <line id="link-distrib-edge" x1="500" y1="300" x2="800" y2="150" stroke="#4ade80" stroke-width="4" />

  <!-- Dispositivos (Nós) -->
  <g id="node-core" transform="translate(200,300)">
    <circle r="25" fill="#1e293b" stroke="#38bdf8" stroke-width="2" />
    <text text-anchor="middle" dy="5" fill="#f8fafc" font-size="10">SW-CORE</text>
  </g>
</svg>
```

## 2. Lógica `onRender` para Atualização de Tráfego

```javascript
// Obtém métricas do DataFrame
const series = data.series;
if (!series || series.length === 0) return;

const trafficLinkCore = htmlGraphics.getSeriesValue('traffic_core_percent');
const linkEl = document.getElementById('link-core-distrib');

if (linkEl && trafficLinkCore !== undefined) {
  if (trafficLinkCore > 90) {
    linkEl.style.stroke = '#ef4444'; // Vermelho (Crítico)
    linkEl.style.strokeWidth = '6';
  } else if (trafficLinkCore > 75) {
    linkEl.style.stroke = '#f59e0b'; // Amarelo (Atenção)
    linkEl.style.strokeWidth = '5';
  } else {
    linkEl.style.stroke = '#22c55e'; // Verde (Normal)
    linkEl.style.strokeWidth = '4';
  }
}
```
