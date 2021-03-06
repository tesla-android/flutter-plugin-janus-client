part of janus_client;

class AudioBridgeJoinedEvent extends AudioBridgeEvent {
  AudioBridgeJoinedEvent({
      audiobridge,
      room,
      this.id, 
      this.display, 
      this.participants,}){
    super.audiobridge=audiobridge;
    super.room=room;

  }

  AudioBridgeJoinedEvent.fromJson(dynamic json) {
    audiobridge = json['audiobridge'];
    room = json['room'];
    id = json['id'];
    display = json['display'];
    if (json['participants'] != null) {
      participants = [];
      json['participants'].forEach((v) {
        participants?.add(AudioBridgeParticipants.fromJson(v));
      });
    }
  }
  int? id;
  String? display;
  List<AudioBridgeParticipants>? participants;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['audiobridge'] = audiobridge;
    map['room'] = room;
    map['id'] = id;
    map['display'] = display;
    if (participants != null) {
      map['participants'] = participants?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

class AudioBridgeParticipants {
  AudioBridgeParticipants({
      this.id, 
    this.display,
      required this.setup,
      required this.muted,
      required this.talking,
      this.spatialPosition,});

  AudioBridgeParticipants.fromJson(dynamic json) {
    id = json['id'];
    display = json['display'];
    setup = json['setup']!=null?json['setup']:setup;
    muted = json['muted']!=null?json['muted']:muted;
    talking = json['talking']!=null?json['talking']:talking;
    spatialPosition = json['spatial_position'];
  }
  int? id;
  String? display;
  bool setup=false;
  bool muted=false;
  bool talking=false;
  int? spatialPosition;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['display'] = display;
    map['setup'] = setup;
    map['muted'] = muted;
    map['talking'] = talking;
    map['spatial_position'] = spatialPosition;
    return map;
  }

}

class AudioBridgeNewParticipantsEvent extends AudioBridgeEvent{
  List<AudioBridgeParticipants>? participants;
  AudioBridgeNewParticipantsEvent.fromJson(dynamic json) {
        audiobridge = json['audiobridge'];
        room = json['room'];
        if (json['participants'] != null) {
          participants = [];
          json['participants'].forEach((v) {
            participants?.add(AudioBridgeParticipants.fromJson(v));
          });
        }
      }
}