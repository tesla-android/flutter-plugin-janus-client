part of janus_client;

class JanusSession {
  late JanusTransport _transport;
  late JanusClient _context;
  int? _sessionId;
  Timer? _keepAliveTimer;
  Map<int?, JanusPlugin> _pluginHandles = {};

  int? get sessionId => _sessionId;

  JanusSession({int? refreshInterval, required JanusTransport transport, required JanusClient context}) {
    _context = context;
    _transport = transport;
  }

  Future<void> create() async {
    try {
      String transaction = getUuid().v4();
      Map<String, dynamic> request = {"janus": "create", "transaction": transaction, ..._context._tokenMap, ..._context._apiMap};
      Map<String, dynamic>? response;
      if (_transport is RestJanusTransport) {
        RestJanusTransport rest = (_transport as RestJanusTransport);
        response = (await rest.post(request)) as Map<String, dynamic>?;
        if (response != null) {
          if (response.containsKey('janus') && response.containsKey('data')) {
            _sessionId = response['data']['id'];
            rest.sessionId = sessionId;
          }
        } else {
          throw "Janus Server not live or incorrect url/path specified";
        }
      } else if (_transport is WebSocketJanusTransport) {
        WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
        if (!ws.isConnected) {
          ws.connect();
        }
        ws.sink!.add(stringify(request));
        response = parse(await ws.stream.firstWhere((element) => (parse(element)['transaction'] == transaction)));
        if (response!.containsKey('janus') && response.containsKey('data')) {
          _sessionId = response['data']['id'] as int?;
          ws.sessionId = sessionId;
        }
      }
      _keepAlive();
    } on WebSocketChannelException catch (e) {
      throw "Connection to given url can't be established\n reason:-" + e.message!;
    } catch (e) {
      throw "Connection to given url can't be established\n reason:-" + e.toString();
    }
  }

  Future<T> attach<T extends JanusPlugin>() async {
    JanusPlugin plugin;
    int? handleId;
    String transaction = getUuid().v4();
    Map<String, dynamic> request = {"janus": "attach", "transaction": transaction};
    request["token"] = _context._token;
    request["apisecret"] = _context._apiSecret;
    request["session_id"] = sessionId;
    Map<String, dynamic>? response;
    if (T == JanusVideoRoomPlugin) {
      plugin = JanusVideoRoomPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusVideoCallPlugin) {
      plugin = JanusVideoCallPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusStreamingPlugin) {
      plugin = JanusStreamingPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusAudioBridgePlugin) {
      plugin = JanusAudioBridgePlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusTextRoomPlugin) {
      plugin = JanusTextRoomPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusEchoTestPlugin) {
      plugin = JanusEchoTestPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusSipPlugin) {
      plugin = JanusSipPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusUstreamerPlugin) {
      plugin = JanusUstreamerPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else {
      throw UnimplementedError('''This Plugin is not defined kindly refer to Janus Server Docs
      make sure you specify the type of plugin you want to attach like session.attach<JanusVideoRoomPlugin>();
      ''');
    }
    request.putIfAbsent("plugin", () => plugin.plugin);
    _context._logger.fine(request);
    if (_transport is RestJanusTransport) {
      _context._logger.info('using rest transport for creating plugin handle');
      RestJanusTransport rest = (_transport as RestJanusTransport);
      response = (await rest.post(request)) as Map<String, dynamic>?;
      _context._logger.fine(response);
      if (response != null && response.containsKey('janus') && response.containsKey('data')) {
        handleId = response['data']['id'];
        rest.sessionId = sessionId;
      } else {
        throw "Network error or janus server not running";
      }
    } else if (_transport is WebSocketJanusTransport) {
      _context._logger.info('using web socket transport for creating plugin handle');
      WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
      if (!ws.isConnected) {
        ws.connect();
      }
      ws.sink!.add(stringify(request));
      response = parse(await ws.stream.firstWhere((element) => (parse(element)['transaction'] == transaction)));
      if (response!.containsKey('janus') && response.containsKey('data')) {
        handleId = response['data']['id'] as int?;
        _context._logger.fine(response);
      }
    }
    plugin.handleId = handleId;
    _pluginHandles[handleId] = plugin;
    try {
      await plugin.init();
    } on MissingPluginException {
      _context._logger.info('Platform exception: i believe you are trying in unit tests, platform specific api not accessible');
    }
    plugin.onCreate();
    return plugin as T;
  }

  void dispose() {
    if (_keepAliveTimer != null) {
      _keepAliveTimer!.cancel();
    }
    if (_transport != null) {
      _transport.dispose();
    }
  }

  _keepAlive() {
    if (sessionId != null) {
      this._keepAliveTimer = Timer.periodic(Duration(seconds: _context._refreshInterval), (timer) async {
        try {
          String transaction = getUuid().v4();
          Map<String, dynamic>? response;
          if (_transport is RestJanusTransport) {
            RestJanusTransport rest = (_transport as RestJanusTransport);
            _context._logger.info("keep alive using RestTransport");
            response = (await rest.post({"janus": "keepalive", "session_id": sessionId, "transaction": transaction, ..._context._apiMap, ..._context._tokenMap})) as Map<String, dynamic>;
            _context._logger.fine(response);
          } else if (_transport is WebSocketJanusTransport) {
            _context._logger.info("keep alive using WebSocketTransport");
            WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
            if (!ws.isConnected) {
              _context._logger.fine("not connected trying to establish connection to webSocket");
              ws.connect();
            }
            ws.sink!.add(stringify({"janus": "keepalive", "session_id": sessionId, "transaction": transaction, ..._context._apiMap, ..._context._tokenMap}));
            _context._logger.fine("keepalive request sent to webSocket");
            response = parse(await ws.stream.firstWhere((element) => (parse(element)['transaction'] == transaction)));
            _context._logger.fine(response);
          }
        } catch (e) {
          timer.cancel();
        }
      });
    }
  }
}
