part of janus_client;

class JanusUstreamerPlugin extends JanusPlugin {
  JanusUstreamerPlugin({handleId, context, transport, session}) : super(context: context, handleId: handleId, plugin: JanusPlugins.USTREAMER, session: session, transport: transport);
}
