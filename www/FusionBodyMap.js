function FusioneticsPlugin () {
}

FusioneticsPlugin.prototype.captureVideo = function (cbSuccess, cbError, options) {
  var cbLifted = function (message) {
    liftedCallback(cbSuccess, cbError, message);
  };

  var exercise = undefined;
  var settings = undefined;

  if (options.exercise && options.exercise !== null)
    exercise = JSON.stringify(options.exercise);

  if (options.settings && options.settings !== null)
    settings = JSON.stringify(options.settings);

  cordova.exec(cbLifted, cbError,
    'FusionBodyMap', 'takeVideo', [markers, settings]);
};


FusioneticsPlugin.prototype.captureImage = function (cbSuccess, cbError, options) {
  var cbLifted = function (message) {
    liftedCallback(cbSuccess, cbError, message);
  };

  var exercise = undefined;
  if (options.exercise && options.exercise !== null)
    exercise = JSON.stringify(options.exercise);

  cordova.exec(cbLifted, cbError,
    'FusionBodyMap', 'playVideo', [exercise]);
};

function liftedCallback (cbSuccess, cbError, message) {
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
}

function parseResults (data) {
  try {
    return { data: JSON.parse(data), valid: true };
  } catch (er) {
    return { data: data, valid: false };
  }
};

module.exports = new FusioneticsPlugin();
