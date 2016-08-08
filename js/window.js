var iframe;

var debug = false;

function respond(response, id) {
  if (debug) console.log(response);
  var msg = {
    'type': 'command-response',
    'id': id,
    'response': response
  }
  iframe.contentWindow.postMessage(msg, '*');
}

var errorHandler = ()=>respond({'result': 'error'});

var commands = {};

// ADD COMMANDS HERE

commands['ping'] = respond;
commands['fetch'] = function(url, id) {
  fetch(url).then((response)=>response.text()).then(function (text) {
    respond(text, id);
  });
}

commands['get-config'] = function(name, id) {
  if (name.startsWith("default-")) {
    commands['fetch']('scheme/config/' + name + '.scm', id);
    return;
  }
  var key = 'config_' + name;
  chrome.storage.sync.get(key, function (items) {
    if(items.hasOwnProperty(key)) {
      respond(items[key], id);
    } else {
      commands['fetch']('scheme/config/' + name + '.scm', id);
    }
  })
}

commands['set-config'] = function(name, contents, id) {
  var input = {}
  input['config_' + name] = contents;
  chrome.storage.sync.set(input, function () {
    respond(null, id);
  });
}

commands['set-local-property'] = function(key, value, id) {
  var input = {}
  input[key] = value;
  chrome.storage.local.set(input, function () {
    respond(null, id);
  })
}

commands['get-local-property'] = function(key, defaultValue, id) {
  chrome.storage.local.get(key, function (items) {
    if (items.hasOwnProperty(key)) {
      respond(items[key], id);
    } else {
      respond(defaultValue, id);
    }
  })
}

commands['user-open-file'] = function(id) {
  chrome.fileSystem.chooseEntry({type: "openWritableFile"}, function (entry) {
    ent = entry;
    respond([entry.fullPath, chrome.fileSystem.retainEntry(entry)], id);
  });
}

commands['user-open-directory'] = function(id) {
  chrome.fileSystem.chooseEntry({type: "openDirectory"}, function (entry) {
    ent = entry;
    respond([entry.fullPath, chrome.fileSystem.retainEntry(entry)], id);
  });
}

commands['read-file'] = function(entryId, id) {
  chrome.fileSystem.restoreEntry(entryId, function (entry) {
    entry.file(function (file) {
      var reader = new FileReader();

      reader.onerror = errorHandler;
      reader.onloadend = function(e) {
        respond(e.target.result, id);
      };
      reader.readAsText(file);
    })
  });
}

commands['save-file'] = function(entryId, contents, id) {
  chrome.fileSystem.restoreEntry(entryId, function (entry) {
    entry.createWriter(function (writer) {
      writer.onerror = errorHandler;
      writer.onwriteend = ()=>respond(null, id);
      writer.write(new Blob([contents]), {type: 'text/plain'});
    }, errorHandler);
  })
}


// END COMMANDS

window.addEventListener('message', function(event) {
  if (event.data.type === 'command') {
    if (!event.data.args) {
      event.data.args = [];
    }
    var args = event.data.args.slice(0);
    args.push(event.data.id);
    if (debug) console.log(args);
    commands[event.data.command].apply(window, args);
  }
});

function init() {
  console.log('Initializing...');
  fetch('scheme/setup.scm').then((response)=>response.text()).then(function (text) {
    var msg = {
      'type': 'init',
      'code': text
    }
    console.log('Posting init code...');
    iframe.contentWindow.postMessage(msg, '*');
  });
}

var timer = setInterval(function() {
  iframe = document.getElementById('frame');
  if (iframe != null) {
    clearInterval(timer);
    init();
  }
}, 300);
