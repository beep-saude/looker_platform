looker.plugins.visualizations.add({
  id: "beep_kpi_em_andamento",
  label: "Beep - KPI Em Andamento (JS)",
  options: {},

  create: function(element, config) {
    element.innerHTML = "<div id='beep-kpi-root' style='height:100%;box-sizing:border-box;'></div>";
  },

  updateAsync: function(data, element, config, queryResponse, details, done) {

    function findField(fields, shortName) {
      return fields.find(function(f) {
        return f.name.split('.').pop() === shortName;
      });
    }

    var allFields = queryResponse.fields.dimensions.concat(queryResponse.fields.measures);
    var esforcoField   = findField(allFields, 'esforco_em_andamento');
    var historiasField = findField(allFields, 'historias_em_andamento');
    var pctField       = findField(allFields, 'pct_esforco_em_andamento');

    var root = element.querySelector('#beep-kpi-root');

    if (!esforcoField || !historiasField || !pctField || data.length === 0) {
      root.innerHTML =
        "<p style='color:#E11515;font-family:Segoe UI,sans-serif;font-size:12px;'>" +
        "Faltam campos na consulta: Esforço Em Andamento, Histórias Em Andamento, % Esforço Em Andamento." +
        "</p>";
      done();
      return;
    }

    var row = data[0];
    var esforco    = row[esforcoField.name].rendered || row[esforcoField.name].value;
    var historias  = row[historiasField.name].rendered || row[historiasField.name].value;
    var pct        = row[pctField.name].rendered || row[pctField.name].value;

    root.innerHTML =
      "<div style='display:flex;flex-direction:column;justify-content:space-between;height:100%;" +
      "box-sizing:border-box;background:#fff;border:1px solid #E0DFD8;border-radius:10px;" +
      "padding:14px 16px;font-family:Segoe UI,sans-serif;'>" +

        "<div style='display:flex;align-items:flex-start;justify-content:space-between;'>" +
          "<div style='font-size:12px;color:#888780;'>Em andamento</div>" +
          "<div style='width:28px;height:28px;background:#FEF0DC;border-radius:8px;" +
          "display:flex;align-items:center;justify-content:center;flex-shrink:0;'>" +
            "<svg width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='#F68300' " +
            "stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'>" +
              "<path d='M12 2a10 10 0 1 0 10 10'/>" +
              "<path d='M12 6v6l4 2'/>" +
              "<path d='M22 2l-5 5'/>" +
              "<path d='M17 2h5v5'/>" +
            "</svg>" +
          "</div>" +
        "</div>" +

        "<div>" +
          "<div style='font-size:26px;font-weight:600;color:#F68300;line-height:1;margin-bottom:3px;'>" +
            esforco + " pts" +
          "</div>" +
          "<div style='font-size:12px;color:#888780;'>" + historias + " histórias · " + pct + "</div>" +
        "</div>" +

      "</div>";

    done();
  }
});
