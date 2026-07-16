looker.plugins.visualizations.add({
  id: "beep_teste_viz",
  label: "Beep - Teste Custom Viz",
  options: {},

  create: function(element, config) {
    element.innerHTML =
      "<div id='beep-donut-root' style='font-family:Segoe UI, sans-serif; padding:16px; position:relative;'>" +
        "<div style='text-align:center;'>" +
          "<canvas id='beep-donut-canvas' width='220' height='220'></canvas>" +
        "</div>" +
        "<div id='beep-donut-legend' style='margin-top:12px;'></div>" +
        "<div id='beep-donut-tooltip' style='display:none;position:fixed;background:#1a1a18;color:#fff;" +
        "border-radius:8px;padding:10px 12px;font-size:11px;font-family:Segoe UI,sans-serif;" +
        "pointer-events:none;z-index:9999;max-width:260px;max-height:240px;overflow-y:auto;'></div>" +
      "</div>";

    var canvas = element.querySelector('#beep-donut-canvas');
    var tooltip = element.querySelector('#beep-donut-tooltip');

    canvas.addEventListener('mousemove', function(e) {
      var slices = canvas._slices;
      if (!slices) return;

      var rect = canvas.getBoundingClientRect();
      var mouseX = e.clientX - rect.left;
      var mouseY = e.clientY - rect.top;
      var dx = mouseX - canvas._cx;
      var dy = mouseY - canvas._cy;
      var dist = Math.sqrt(dx * dx + dy * dy);

      if (dist < canvas._innerR || dist > canvas._outerR) {
        tooltip.style.display = 'none';
        canvas.style.cursor = 'default';
        return;
      }

      var angle = Math.atan2(dy, dx);
      var startRef = -Math.PI / 2;
      while (angle < startRef) angle += 2 * Math.PI;
      while (angle >= startRef + 2 * Math.PI) angle -= 2 * Math.PI;

      var hovered = null;
      for (var i = 0; i < slices.length; i++) {
        var s = slices[i];
        if (s.total > 0 && angle >= s.startAngle && angle < s.endAngle) {
          hovered = s;
          break;
        }
      }

      if (!hovered) {
        tooltip.style.display = 'none';
        canvas.style.cursor = 'default';
        return;
      }

      canvas.style.cursor = 'pointer';

      var pct = canvas._total > 0 ? Math.round((hovered.total / canvas._total) * 100) : 0;

      var storiesHtml = hovered.stories
        .slice()
        .sort(function(a, b) { return b.estimate - a.estimate; })
        .map(function(st) {
          var cor = st.state === 'done' ? '#00AFAA' : (st.state === 'started' ? '#F68300' : '#B4B2A9');
          return (
            "<div style='display:flex;align-items:center;gap:6px;margin-top:4px;'>" +
              "<span style='width:6px;height:6px;border-radius:50%;background:" + cor + ";flex-shrink:0;display:inline-block;'></span>" +
              "<span style='flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;'>" + (st.name || '(sem nome)') + "</span>" +
              "<span style='color:#aaa;flex-shrink:0;margin-left:6px;'>" + st.estimate + " pts</span>" +
            "</div>"
          );
        }).join('');

      tooltip.innerHTML =
        "<div style='font-weight:600;margin-bottom:6px;border-bottom:1px solid rgba(255,255,255,0.2);padding-bottom:4px;'>" +
          hovered.label + " — " + hovered.total + " pts (" + pct + "%)" +
        "</div>" + storiesHtml;

      tooltip.style.display = 'block';
      tooltip.style.left = (e.clientX + 14) + 'px';
      tooltip.style.top = (e.clientY + 14) + 'px';
    });

    canvas.addEventListener('mouseleave', function() {
      tooltip.style.display = 'none';
      canvas.style.cursor = 'default';
    });
  },

  updateAsync: function(data, element, config, queryResponse, details, done) {

    function findField(fields, shortName) {
      return fields.find(function(f) {
        return f.name.split('.').pop() === shortName;
      });
    }

    var allFields = queryResponse.fields.dimensions.concat(queryResponse.fields.measures);
    var devTypeField   = findField(allFields, 'story_dev_type');
    var estimateField  = findField(allFields, 'estimate');
    var storyNameField = findField(allFields, 'story_name');
    var stateTypeField = findField(allFields, 'state_type');

    if (!devTypeField || !estimateField) {
      element.querySelector('#beep-donut-root').innerHTML =
        "<p style='color:#E11515;'>Faltam campos na consulta: adiciona Story Dev Type, Estimate, Story Name e State Type.</p>";
      done();
      return;
    }

    var groups = {};
    data.forEach(function(row) {
      var devTypeRaw = row[devTypeField.name].value;
      var devType = devTypeRaw || "Sem tipo";
      var estimate = row[estimateField.name].value || 0;

      if (!groups[devType]) {
        groups[devType] = { total: 0, stories: [] };
      }
      groups[devType].total += estimate;

      groups[devType].stories.push({
        name: storyNameField ? row[storyNameField.name].value : null,
        estimate: estimate,
        state: stateTypeField ? row[stateTypeField.name].value : null
      });
    });

    var categoryOrder = ["Projeto estruturante", "Bug & Sustentação", "Melhorias rápidas", "Sem tipo"];
    var categoryColors = {
      "Projeto estruturante": "#00AFAA",
      "Bug & Sustentação": "#E11515",
      "Melhorias rápidas": "#FBA600",
      "Sem tipo": "#B4B2A9"
    };

    var slices = categoryOrder.map(function(cat) {
      var g = groups[cat];
      return {
        label: cat,
        color: categoryColors[cat],
        total: g ? g.total : 0,
        stories: g ? g.stories : []
      };
    });

    var total = slices.reduce(function(sum, s) { return sum + s.total; }, 0);

    var canvas = element.querySelector('#beep-donut-canvas');
    var ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    var cx = canvas.width / 2;
    var cy = canvas.height / 2;
    var outerR = Math.min(cx, cy) - 10;
    var innerR = outerR * 0.62;
    var start = -Math.PI / 2;

    slices.forEach(function(s) {
      var angle = total > 0 ? (s.total / total) * 2 * Math.PI : 0;
      s.startAngle = start;
      s.endAngle = start + angle;

      if (s.total > 0 && total > 0) {
        ctx.beginPath();
        ctx.arc(cx, cy, outerR, start, start + angle);
        ctx.arc(cx, cy, innerR, start + angle, start, true);
        ctx.closePath();
        ctx.fillStyle = s.color;
        ctx.fill();
      }
      start += angle;
    });

    ctx.fillStyle = '#1a1a18';
    ctx.font = '600 16px Segoe UI, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(total + ' pts', cx, cy);

    // Guarda os dados calculados no próprio elemento canvas,
    // pra o listener de mousemove (criado 1x no create) sempre ler a versão mais atual
    canvas._slices = slices;
    canvas._cx = cx;
    canvas._cy = cy;
    canvas._innerR = innerR;
    canvas._outerR = outerR;
    canvas._total = total;

    var legendHtml = slices.map(function(s) {
      var pct = total > 0 ? Math.round((s.total / total) * 100) : 0;
      return (
        "<div style='display:inline-block; margin-right:16px; margin-bottom:6px; font-size:12px;'>" +
          "<span style='display:inline-block; width:9px; height:9px; border-radius:2px; background:" + s.color + "; margin-right:5px;'></span>" +
          s.label + " — " + s.total + " pts (" + pct + "%)" +
        "</div>"
      );
    }).join('');

    element.querySelector('#beep-donut-legend').innerHTML = legendHtml;

    done();
  }
});
