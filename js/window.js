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

function makeErrorHandler(id) {
  return ()=>respond({'result': 'error'}, id);
}

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
  var w = name == 'local-config' ? chrome.storage.local : chrome.storage.sync;
  var key = 'config_' + name;
  w.get(key, function (items) {
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
  var w = name == 'local-config' ? chrome.storage.local : chrome.storage.sync;
  w.set(input, function () {
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

      reader.onerror = makeErrorHandler(id);
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
      var truncated = false;
      var blob = new Blob([contents]);

      writer.onwriteend = function(e) {
        if (!truncated) {
          truncated = true;
          // You need to explicitly set the file size to truncate
          // any content that might have been there before
          this.truncate(blob.size);
        }
        respond("success!", id);
      };
      writer.onerror = makeErrorHandler(id);
      writer.write(blob, {type: 'text/plain'});
    }, makeErrorHandler(id));
  })
}

var socket;

commands['websocket-init'] = function(url, id) {
  socket = new WebSocket(url);
  socket.onopen = ()=>respond("success", id);
  socket.onmessage = (event)=>{
    var msg = {
      'type': 'websocket-message',
      'msg': JSON.parse(event.data)
    }
    iframe.contentWindow.postMessage(msg, '*');
  };
  socket.onerror = ()=>{
    respond("failure", id);
    var msg = {
      'type': 'websocket-error'
    }
    iframe.contentWindow.postMessage(msg, '*');
  };
  socket.onclose = ()=>{
    var msg = {
      'type': 'websocket-close'
    }
    iframe.contentWindow.postMessage(msg, '*');
  };
}

commands['websocket-send'] = function(msgObj, id) {
  try {
    if (socket && socket.readyState === 1) {
      socket.send(JSON.stringify(msgObj));
      respond("success", id);
    } else {
      throw(new Error(""));
    }
  } catch(e) {
    respond("failure", id);
  }
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

window.addEventListener('keydown', function(e) {
  if (e.ctrlKey && e.keyCode == 87) {
    e.preventDefault();
  }
});
