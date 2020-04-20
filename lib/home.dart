import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:nocna_mora/widget.dart';
import 'package:provider/provider.dart';

import 'constants.dart' as Constant;

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  var _logger = Logger();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          builder: (context) => _LegendSchedule(),
        )
      ],
      child: Scaffold(
        backgroundColor: Color(0xFF303030),
        body: Stack(
          children: <Widget>[
            Container(
              height: 500,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8.0,
                  )
                ],
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(0), bottom: Radius.circular(200)),
                color: Constant.primaryColor,
                shape: BoxShape.rectangle,
              ),
            ),
            NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScroller) {
                var legendSchedule = Provider.of<_LegendSchedule>(context);
                return <Widget>[
                  SliverAppBar(
                    expandedHeight: 280.0,
                    pinned: true,
                    floating: true,
                    snap: true,
                    flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        centerTitle: false,
                        title: Text(
                            legendSchedule.document == null
                                ? ""
                                : legendSchedule.document["name"],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            )),
                        background: Center(
                          child: Container(
                            width: 280,
                            height: 280,
                            child: Center(
                              child: Stack(
                                children: <Widget>[
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 4.0)),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                          legendSchedule.document == null
                                              ? ""
                                              : legendSchedule
                                                  .document["image"]),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 120,
                                    width: 100,
                                    child: Stack(
                                      children: <Widget>[
                                        Positioned(
                                          bottom: 0,
                                          left: 30,
                                          child: Text(
                                            (legendSchedule.document != null &&
                                                    legendSchedule.document[
                                                            "loves"] !=
                                                        null)
                                                ? getLovesPretty(legendSchedule
                                                    .document["loves"])
                                                : "",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        (legendSchedule.document != null &&
                                                legendSchedule
                                                        .document["loves"] !=
                                                    null)
                                            ? Icon(
                                                FontAwesomeIcons.heartbeat,
                                                color: Colors.white,
                                                size: 40,
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ),
                ];
              },
              body: StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance.collection("legends").snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                          child: AppWidgets
                              .createSimpleExpendedSizedBoxProgress());
                    }

                    var legendSchedule = Provider.of<_LegendSchedule>(context);
                    if (legendSchedule.document == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setPageStateFor(
                            snapshot.data.documents[0], legendSchedule);
                      });
                    }
                    return Stack(
                      children: <Widget>[
                        PageView(
                          controller: PageController(initialPage: 0),
                          children:
                              createLegendPageItems(snapshot.data.documents),
                          onPageChanged: (index) {
                            if (snapshot.hasData) {
                              setPageStateFor(snapshot.data.documents[index],
                                  legendSchedule);
                            }
                          },
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClapFAB.icon(
                              countCircleColor: Constant.primaryColor,
                              defaultIconColor: Colors.white,
                              floatingBgColor: Constant.primaryColor,
                              floatingOutlineColor: Constant.primaryColor,
                              hasShadow: true,
                              sparkleColor: Colors.green,
                              shadowColor: Constant.primaryColor,
                              filledIconColor: Colors.white,
                              clapFabCallback: (counter) {
                                handleCount(counter, legendSchedule.document);
                              },
                            ),
                          ),
                        )
                      ],
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  String getLovesPretty(int loves) {
    return NumberFormat.compact().format(loves);
  }

  List<Widget> createLegendPageItems(List<DocumentSnapshot> documentSnapshots) {
    List<Widget> list = List();
    for (int i = 0; i < documentSnapshots.length; i++) {
      list.add(_LegendVoicesListView(documentSnapshots[i]));
    }

    return list;
  }

  void setPageStateFor(
      DocumentSnapshot document, _LegendSchedule legendSchedule) {
    legendSchedule.document = document;
  }

  void handleCount(int count, DocumentSnapshot documentSnapshot) {
    Firestore.instance.runTransaction((transaction) async {
      try {
        DocumentSnapshot remoteSnapshot =
            await transaction.get(documentSnapshot.reference);
        var totalCount = remoteSnapshot["loves"] + count;
        await transaction
            .update(remoteSnapshot.reference, {"loves": totalCount});
      } catch (e) {
        _logger.d("something went wrong: " + e.toString());
      }
    });
  }
}

class _LegendVoicesListView extends StatelessWidget {
  final DocumentSnapshot documentSnapshot;

  _LegendVoicesListView(this.documentSnapshot);

  @override
  Widget build(BuildContext context) {
    List<dynamic> voices = documentSnapshot["voices"];
    return ListView.builder(
      itemBuilder: (context, index) {
        return _VoiceItem2(voice: voices[index]);
      },
      itemCount: voices == null ? 0 : voices.length,
    );
  }
}

class _VoiceItem2 extends StatefulWidget {
  final voice;

  const _VoiceItem2({Key key, this.voice}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _VoiceItemState(voice);
  }
}

class _VoiceItemState extends State<_VoiceItem2> with WidgetsBindingObserver {
  final _logger = Logger();
  final _voice;

  StreamSubscription _audioPlayerStateSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _durationSubscription;

  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  AudioPlayer _audioPlayer;
  Future<int> _future;
  AudioPlayerState _playerState = AudioPlayerState.STOPPED;
  var _isPaused = false;

  _VoiceItemState(this._voice);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
              top: 0,
              left: 30,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(40.0),
                  ),
                ),
                elevation: 8.0,
                child: InkWell(
                  splashColor: Constant.primaryColor30,
                  onTap: playMusic,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                            child: Text(
                              _voice["name"] == null ? "" : _voice["name"],
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.normal),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: PopupMenuButton(
                            elevation: 8.0,
                            itemBuilder: (context) {
                              return <String>['Add to Favorite', 'Share']
                                  .map((value) {
                                return PopupMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                          value == "Share"
                                              ? FontAwesomeIcons.share
                                              : FontAwesomeIcons.solidStar,
                                          color: Constant.primaryColor),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text(
                                          value,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                            icon: Icon(
                              FontAwesomeIcons.ellipsisV,
                              color: Constant.primaryColor,
                            ),
                            onSelected: handleOnIemSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
                child: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.center,
                      child: _playerState == AudioPlayerState.PAUSED
                          ? BlinkAnimatedIcon(
                              iconData: FontAwesomeIcons.pause,
                            )
                          : Icon(
                              _playerState == AudioPlayerState.PLAYING
                                  ? FontAwesomeIcons.pause
                                  : FontAwesomeIcons.play,
                              color: Colors.white,
                            ),
                    ),
                    FutureBuilder(
                      future: _future,
                      builder: (context, snapshot) {
                        var state = snapshot.connectionState;
                        return Center(
                            child: SizedBox(
                                width: 52,
                                height: 52,
                                child: AnimatedOpacity(
                                    opacity:
                                        (state == ConnectionState.waiting ||
                                                _playerState ==
                                                    AudioPlayerState.PLAYING ||
                                                _playerState ==
                                                    AudioPlayerState.PAUSED)
                                            ? 1.0
                                            : 0.0,
                                    duration: Duration(milliseconds: 200),
                                    child: AnimatedCircularProgressIndicator(
                                        value: computeProgressValue()))));
                      },
                    )
                  ],
                ),
                width: 60.0,
                height: 80.0,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Constant.primaryColor,
                    border: Border.all(
                        color: Constant.primaryColorDark, width: 2))),
          ),
        ],
      ),
    );
  }

  void handleOnIemSelected(value) async {
    _logger.d(value);
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _logger.d("dispose");
    super.dispose();
    disposePlayerAndCancelSubscriptions();
    WidgetsBinding.instance.removeObserver(this);
  }

  bool pausePlayer() {
    if (_playerState == AudioPlayerState.PLAYING) {
      _audioPlayer?.pause();
      return true;
    }

    return false;
  }

  void resumePlayer() {
    if (_playerState == AudioPlayerState.PAUSED) {
      _audioPlayer?.resume();
    }
  }

  void playMusic() {
    _logger.d("playMusic");
    if (_playerState == AudioPlayerState.PLAYING) {
      if (_duration == Duration.zero) {
        return;
      }
      pausePlayer();
    } else if (_playerState == AudioPlayerState.PAUSED) {
      resumePlayer();
    } else {
      if (_audioPlayer != null) {
        dispose();
        setState(() {
          _playerState = AudioPlayerState.STOPPED;
        });
      }

      _logger.d("audioPlayer...creating new one");
      _audioPlayer = AudioPlayer();

      setState(() {
        try {
          _future =
              _audioPlayer.play(_voice["file"], isLocal: false, volume: 1.0);
        } catch (e) {}
      });

      _positionSubscription = _audioPlayer.onAudioPositionChanged.listen(
        (currentPosition) {
          setState(() {
            _logger.d("currentPosition $currentPosition");
            _currentPosition = currentPosition;
          });
        },
      );

      _audioPlayer.onDurationChanged.listen((duration) {
        setState(() {
          _logger.d("max duration $duration");
          _duration = duration;
        });
      });

      _audioPlayerStateSubscription = _audioPlayer.onPlayerStateChanged.listen(
        ((state) {
          setState(() {
            this._playerState = state;
            _logger.d("on playerState $state");
          });

          if (state == AudioPlayerState.COMPLETED) {
            disposePlayerAndCancelSubscriptions();
          }
        }),
        onError: (msg) {
          _logger.d(msg);
          disposePlayerAndCancelSubscriptions();
        },
        onDone: () {
          _logger.d("on onDone ");
        },
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isPaused = pausePlayer();
    } else if (state == AppLifecycleState.resumed) {
      if (_isPaused) {
        resumePlayer();
        _isPaused = false;
      }
    }
    _logger.d(state.toString());
  }

  void disposePlayerAndCancelSubscriptions() {
    _logger.d("disposePlayerAndCancelSubscriptions...");
    _audioPlayerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _duration = Duration.zero;
    _currentPosition = Duration.zero;

    setState(() {
      _playerState = AudioPlayerState.STOPPED;
    });
  }

  double computeProgressValue() {
    if (_duration == Duration.zero) {
      return null;
    }

    if (_currentPosition == Duration.zero) {
      return 0.0;
    }

    if (_playerState == AudioPlayerState.COMPLETED) {
      return 1.0;
    }
    return _currentPosition.inMilliseconds / _duration.inMilliseconds;
  }
}

class _LegendSchedule with ChangeNotifier {
  var _document;

  set document(DocumentSnapshot document) {
    _document = document;
    notifyListeners();
  }

  DocumentSnapshot get document {
    return _document;
  }
}

class AnimatedCircularProgressIndicator extends StatefulWidget {
  final double value;

  const AnimatedCircularProgressIndicator({Key key, this.value})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _AnimatedCircularProgressIndicatorState(value);
  }
}

class _AnimatedCircularProgressIndicatorState
    extends State<AnimatedCircularProgressIndicator>
    with TickerProviderStateMixin {
  double value;

  Animation<double> _animation;
  AnimationController _controller;
  CurvedAnimation _curve;

  _AnimatedCircularProgressIndicatorState(this.value);

  initState() {
    super.initState();
    initController();
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null
        ? CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.white))
        : AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CircularProgressIndicator(
                  value: _animation.value,
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.white));
            },
          );
  }

  @override
  void didUpdateWidget(AnimatedCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    double oldValue = value == null ? 0.0 : value;
    value = oldWidget.value;

    if (value == null) {
      destroyController();
    } else if (_controller == null) {
      initController();
    } else {
      double begin = _animation.value ?? oldValue;
      _animation = Tween<double>(begin: begin, end: value).animate(_curve);
      _controller
        ..value = 0
        ..forward();
    }
  }

  void initController() {
    if (value != null) {
      _controller = AnimationController(
          duration: Duration(milliseconds: 250), vsync: this);
      _curve = CurvedAnimation(parent: _controller, curve: Curves.linear);
      _animation = Tween<double>(begin: 0.0, end: value).animate(_curve);

      setState(() {});
      _controller.forward();
    }
  }

  void destroyController() {
    if (_controller != null) {
      _controller.stop(canceled: true);
      _controller = null;
      setState(() {
        _animation = null;
      });
    }
  }
}

class BlinkAnimatedIcon extends StatefulWidget {
  final IconData iconData;

  const BlinkAnimatedIcon({Key key, @required this.iconData})
      : assert(iconData != null),
        super(key: key);

  @override
  _BlinkAnimatedIconState createState() => _BlinkAnimatedIconState(iconData);
}

class _BlinkAnimatedIconState extends State<BlinkAnimatedIcon>
    with SingleTickerProviderStateMixin {
  final IconData iconData;

  Animation<Color> _animation;
  AnimationController _controller;

  _BlinkAnimatedIconState(this.iconData);

  initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    final CurvedAnimation curve =
        CurvedAnimation(parent: _controller, curve: Curves.linear);
    _animation =
        ColorTween(begin: Colors.white, end: Constant.primaryColorLight)
            .animate(curve);
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
      setState(() {});
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget child) {
        return Icon(
          iconData,
          color: _animation.value,
        );
      },
    );
  }

  dispose() {
    _controller.dispose();
    super.dispose();
  }
}
