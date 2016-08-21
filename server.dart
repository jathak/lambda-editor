/// Simple websocket server that allows for the editor to run terminal commands
/// and write to files
/// May eventually add other features
/// Only allows for connections from localhost for security reasons.
/// This script and the Scheme library in the editor that connects with it
/// expects that it is run in a Unix-like environment.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// change client hosts that this server will accept
// I've added 'ubuntu' because thats the hostname of the VM on my Windows machine
List ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'ubuntu'];

// this may vary
List ALLOWED_ORIGINS = ['chrome-extension://mhiojnfeldhbngifldjpohdncclpooop'];

HttpServer server;
int port = 6320;

main(var args) async {
  if (args.isNotEmpty) {
    port = int.parse(args[0]);
  }
  server = await HttpServer.bind(InternetAddress.ANY_IP_V4, port);
  print("Connect to ws://localhost:$port");
  print("This server must remain running for the editor to work.");
  await for (var request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request) || !validateRequest(request)) {
      request.response.statusCode = HttpStatus.FORBIDDEN;
      request.response.close();
      continue;
    }
    print("Connected to page at ${request.headers.value('origin')}");
    WebSocket socket = await WebSocketTransformer.upgrade(request);
    await for (var encodedMsg in socket) {
      try {
        print("Received $encodedMsg");
        var msg = JSON.decode(encodedMsg);
        msg['socket'] = socket;
        handleMessage(msg).then((result) {
          respond({'result': result}, msg);
        }, onError: (error) {
          respond({'result': 'error'}, msg, 'error');
        });
      } catch (e, st) {
        print(e);
        print(st);
      }
    }
    print("Disconnected from client.");
  }
}

bool validateRequest(request) {
  if (!ALLOWED_HOSTS.contains(request.headers.value('host').split(":")[0])) return false;
  if (!ALLOWED_ORIGINS.contains(request.headers.value('origin'))) return false;
  return true;
}

send(msg, socket) {
  print("preencoded $msg");
  var str = JSON.encode(msg);
  socket.add(str);
  print("Sent $str");
}
respond(msg, original, [type = 'response']) {
  msg['type'] = type;
  msg['msg-id'] = original['msg-id'];
  send(msg, original['socket']);
}

var activeProcesses = {};

handleMessage(msg) async {
  var type = msg['type'];
  if (type == 'run') {
    var exec = msg['command'];
    var wd = msg.containsKey('directory') ? msg['directory'] : Directory.current.path;
    if (wd.startsWith('~')) {
      wd = Platform.environment['HOME'] + wd.substring(1);
    }
    var result = await Process.run('bash', ['-c', exec], workingDirectory: wd);
    return {'stdout': result.stdout, 'stderr': result.stderr};
  } else if (type == 'start') {
    var exec = msg['command'];
    var wd = msg.containsKey('directory') ? msg['directory'] : Directory.current.path;
    if (wd.startsWith('~')) {
      wd = Platform.environment['HOME'] + wd.substring(1);
    }
    var process = await Process.start('bash', ['-c', exec], workingDirectory: wd);
    process.exitCode.then((code) => respond({'exit-code': code}, msg, 'process-exit'));
    process.stdout
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen((line) => respond({'line': line}, msg, 'stdout'));
    process.stderr
      .transform(UTF8.decoder)
      .transform(new LineSplitter())
      .listen((line) => respond({'line': line}, msg, 'stderr'));
    activeProcesses[process.pid] = process;
    return process.pid;
  } else if (type == 'input') {
    var process = activeProcesses[msg['pid']];
    process.stdin.write(msg['input']);
    return null;
  } else if (type == 'write-file') {
    var path = msg['path'];
    if (path.startsWith('~')) {
      path = Platform.environment['HOME'] + path.substring(1);
    }
    var contents = msg['contents'];
    File file = await new File(path).create(recursive: true);
    await file.writeAsString(contents);
    return null;
  }
}
