looker.plugins.visualizations.add({
  id: "beep_teste_viz",
  label: "Beep - Teste Custom Viz",
  options: {},

  create: function(element, config) {
    element.innerHTML = "<div id='beep-viz-container' style='font-family:Segoe UI, sans-serif; padding:16px;'></div>";
  },

  updateAsync: function(data, element, config, queryResponse, details, done) {
    var container = element.querySelector('#beep-viz-container');

    var numRows = data.length;
    var fields = queryResponse.fields.dimensions.concat(queryResponse.fields.measures);
    var fieldNames = fields.map(function(f) { return f.label_short || f.label; }).join(', ');

    var primeiraLinha = "";
    if (data.length > 0) {
      primeiraLinha = JSON.stringify(data[0], null, 2);
    }

    container.innerHTML =
      "<h3 style='margin:0 0 8px 0;'>Teste de Visualização Customizada</h3>" +
      "<p><strong>Linhas recebidas:</strong> " + numRows + "</p>" +
      "<p><strong>Campos na consulta:</strong> " + fieldNames + "</p>" +
      "<pre style='background:#f1efe8;padding:10px;border-radius:6px;font-size:11px;overflow:auto;max-height:300px;'>" +
      primeiraLinha.replace(/</g, "&lt;") +
      "</pre>";

    done();
  }
});
