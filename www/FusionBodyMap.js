function FusioneticsPlugin () {
}

FusioneticsPlugin.prototype.captureVideo = function (cbSuccess, cbError, options) {
  var cbLifted = function (message) {
    var json = parseResults(message);
    if (!json.valid) {
      cbError('Unable to parse plugin result.')
      return;
    }

    var data = json.data;
    cbSuccess({
      cancelled: data.cancelled,
      capturedVideo: data.capturedVideo,
      capturedImage: data.capturedImage,
      videoUrl: data.videoUrl,
      videoImage: data.videoImage,
      videoTimestamp: data.videoTimestamp
    });
  };

  cordova.exec(cbLifted, cbError,
    'FusionBodyMap', 'takeVideo', []);
};

function parseResults (data) {
  try {
    return { data: JSON.parse(data), valid: true };
  } catch (er) {
    return { data: data, valid: false };
  }
};

module.exports = new FusioneticsPlugin();
