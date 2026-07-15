looker.plugins.visualizations.add({
  id: "beep_teste_viz",
  label: "Beep - Teste Custom Viz",
  options: {},

  create: function(element, config) {
    element.innerHTML =
      "<div id='beep-donut-root' style='font-family:Segoe UI, sans-serif; padding:16px; display:block;'>" +
        "<div style='text-align:center;'>" +
          "<canvas id='beep-donut-canvas' width='220' height='220'></canvas>" +
        "</div>" +
        "<div id='beep-donut-legend' style='margin-top:12px;'></div>" +
      "</div>";
  },

  updateAsync: function(data, element, config, queryResponse, details, done) {

    function findField(fields, shortName) {
      return fields.find(function(f) {
        return f.name.split('.').pop() === shortName;
      });
    }

    var allFields = queryResponse.fields.dimensions.concat(queryResponse.fields.measures);
    var devTypeField    = findField(allFields, 'story_dev_type');
    var estimateField   = findField(allFields, 'estimate');
    var storyNameField  = findField(allFields, 'story_name');
    var stateTypeField  = findField(allFields, 'state_type');

    if (!devTypeField || !estimateField) {
      element.querySelector('#beep-donut-root').innerHTML =
        "<p style='color:#E11515;'>Faltam campos na consulta: adiciona Story Dev Type, Estimate, Story Name e State Type.</p>";
      done();
      return;
    }

    // Agrupa os dados por tipo de desenvolvimento
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

    // Categorias fixas, na mesma ordem e cores do dashboard original
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

    // Desenha o donut
    var canvas = element.querySelector('#beep-donut-canvas');
    var ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    var cx = canvas.width / 2;
    var cy = canvas.height / 2;
    var outerR = Math.min(cx, cy) - 10;
    var innerR = outerR * 0.62;
    var start = -Math.PI / 2;

    slices.forEach(function(s) {
      if (total <= 0 || s.total <= 0) return;
      var angle = (s.total / total) * 2 * Math.PI;
      ctx.beginPath();
      ctx.arc(cx, cy, outerR, start, start + angle);
      ctx.arc(cx, cy, innerR, start + angle, start, true);
      ctx.closePath();
      ctx.fillStyle = s.color;
      ctx.fill();
      start += angle;
    });

    ctx.fillStyle = '#1a1a18';
    ctx.font = '600 16px Segoe UI, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(total + ' pts', cx, cy);

    // Monta a legenda
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
